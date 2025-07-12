import 'package:flutter/material.dart';
import 'dart:async'; // the import for Timer
import 'dart:io';
import '../product.dart';
import '../shopping_list.dart';
import '../db__helper.dart';

class ShoppingModePage extends StatefulWidget {
  final int shoppingListId;

  const ShoppingModePage({super.key, required this.shoppingListId});

  @override
  State<ShoppingModePage> createState() => _ShoppingModePageState();
}

class _ShoppingModePageState extends State<ShoppingModePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  ShoppingList? _shoppingList;
  List<ShoppingListItem> _items = [];
  Map<int, Product> _products = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingData();
  }

  Future<void> _loadShoppingData() async {
    try {
      // Load shopping list
      final lists = await _dbHelper.getAllShoppingLists();
      final list = lists.firstWhere((l) => l.id == widget.shoppingListId);

      // Load shopping list items
      final items = await _dbHelper.getShoppingListItems(widget.shoppingListId);

      // OPTIMIZED: Load all products ONCE before the loop
      final allProducts = await _dbHelper.getAllProducts();
      final products = <int, Product>{};

      for (final item in items) {
        try {
          final product = allProducts.firstWhere((p) => p.id == item.productId);
          products[item.productId] = product;
        } catch (e) {
          // Handle case where product doesn't exist anymore
          print('Product with ID ${item.productId} not found');
        }
      }

      if (mounted) {
        setState(() {
          _shoppingList = list;
          _items = items;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleItemChecked(ShoppingListItem item) async {
    try {
      // Toggle item state
      final updatedItem = item.copyWith(isChecked: !item.isChecked);

      // Update in database
      await _dbHelper.updateShoppingListItem(updatedItem);

      // Update UI
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = updatedItem;
        }
      });

      // Visual feedback with animation
      if (updatedItem.isChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${_products[item.productId]?.name} purchased!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _finishShopping() async {
    final checkedCount = _items.where((item) => item.isChecked).length;
    final totalCount = _items.length;

    if (checkedCount < totalCount) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Finish Shopping?'),
          content: Text(
            'You have purchased $checkedCount out of $totalCount items.\n'
            'Do you really want to finish?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continue Shopping'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Finish'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    try {
      // Mark list as inactive (completed)
      final completedList = _shoppingList!.copyWith(isActive: false);
      await _dbHelper.updateShoppingList(completedList);

      if (!mounted) return;

      // Congratulations message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Shopping completed! $checkedCount/$totalCount items purchased',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Return to main page
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Optional improvement - different tap behaviors
  bool _singleTapActive = false;

  void _handleTap(ShoppingListItem item) {
    _singleTapActive = true;
    Timer(const Duration(milliseconds: 250), () {
      if (_singleTapActive) {
        // Single tap: toggle checked state
        _toggleItemChecked(item);
      }
    });
  }

  void _handleDoubleTap(ShoppingListItem item) {
    _singleTapActive = false;
    // Double tap: could show edit dialog or different action
    _showItemEditDialog(item);
  }

  Future<void> _showItemEditDialog(ShoppingListItem item) async {
    final product = _products[item.productId];
    if (product == null) return;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current quantity: ${item.quantity}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, item.quantity - 1),
                  child: const Icon(Icons.remove),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, item.quantity + 1),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0), // Remove item
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != null) {
      if (result <= 0) {
        // Remove item from list
        await _removeItemFromList(item);
      } else {
        // Update quantity
        await _updateItemQuantity(item, result);
      }
    }
  }

  Future<void> _updateItemQuantity(
    ShoppingListItem item,
    int newQuantity,
  ) async {
    try {
      final updatedItem = item.copyWith(quantity: newQuantity);
      await _dbHelper.updateShoppingListItem(updatedItem);

      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = updatedItem;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantity updated to $newQuantity'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeItemFromList(ShoppingListItem item) async {
    try {
      await _dbHelper.deleteShoppingListItem(item.id!);

      setState(() {
        _items.removeWhere((i) => i.id == item.id);
      });

      if (mounted) {
        final product = _products[item.productId];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product?.name ?? "Item"} removed from list'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_shoppingList == null || _items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping Mode')),
        body: const Center(child: Text('No items in this shopping list.')),
      );
    }

    final checkedCount = _items.where((item) => item.isChecked).length;
    final totalCount = _items.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_shoppingList!.name),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _finishShopping,
            icon: const Icon(Icons.check_circle),
            tooltip: 'Finish',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(bottom: BorderSide(color: Colors.green.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      '$checkedCount / $totalCount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green.shade600,
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final product = _products[item.productId];

                if (product == null) {
                  return const ListTile(
                    title: Text('Product not found'),
                    leading: Icon(Icons.error, color: Colors.red),
                  );
                }

                return GestureDetector(
                  onTap: () => _handleTap(item),
                  onDoubleTap: () => _handleDoubleTap(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isChecked
                          ? Colors.grey.shade100
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.isChecked
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Product photo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child:
                                  product.photoPath != null &&
                                      File(product.photoPath!).existsSync()
                                  ? ColorFiltered(
                                      colorFilter: item.isChecked
                                          ? const ColorFilter.mode(
                                              Colors.grey,
                                              BlendMode.saturation,
                                            )
                                          : const ColorFilter.mode(
                                              Colors.transparent,
                                              BlendMode.multiply,
                                            ),
                                      child: Image.file(
                                        File(product.photoPath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      color: item.isChecked
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade200,
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey.shade600,
                                        size: 30,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: item.isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.isChecked
                                        ? Colors.grey.shade600
                                        : Colors.black,
                                  ),
                                ),

                                if (product.category != null)
                                  Text(
                                    product.category!,
                                    style: TextStyle(
                                      color: item.isChecked
                                          ? Colors.grey.shade500
                                          : Colors.blue.shade600,
                                      fontSize: 12,
                                    ),
                                  ),

                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    Text(
                                      'Quantity: ${item.quantity}',
                                      style: TextStyle(
                                        color: item.isChecked
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    if (product.price != null) ...[
                                      const SizedBox(width: 16),
                                      Text(
                                        '€${(product.price! * item.quantity).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: item.isChecked
                                              ? Colors.grey.shade500
                                              : Colors.green.shade600,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Status icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.isChecked
                                  ? Colors.green.shade100
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.isChecked
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: item.isChecked
                                  ? Colors.green.shade600
                                  : Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Floating action button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finishShopping,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.shopping_cart_checkout),
        label: Text('Finish ($checkedCount/$totalCount)'),
      ),
    );
  }
}
