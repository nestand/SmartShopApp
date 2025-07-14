import 'package:flutter/material.dart';
import 'dart:io';
import '../../product.dart';
import '../../shopping_list.dart';
import '../../db__helper.dart';

class ShoppingListCreationPage extends StatefulWidget {
  final ShoppingList? existingList;
  final bool allowEmpty;

  const ShoppingListCreationPage({
    super.key,
    this.existingList,
    this.allowEmpty = false,
  });

  @override
  State<ShoppingListCreationPage> createState() =>
      _ShoppingListCreationPageState();
}

class _ShoppingListCreationPageState extends State<ShoppingListCreationPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nameController = TextEditingController();

  List<Product> _allProducts = [];
  final Set<int> _selectedProductIds = <int>{};
  final Map<int, int> _quantities = <int, int>{};

  bool get _isEditMode => widget.existingList != null;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize form data and load products
  Future<void> _initializeData() async {
    // Set default name
    _nameController.text = _isEditMode
        ? widget.existingList!.name
        : 'Shopping List ${DateTime.now().day}/${DateTime.now().month}';

    // Load products first, then existing list data if editing
    await _loadProducts();

    if (_isEditMode) {
      await _loadExistingListData();
    }
  }

  /// Load all available products from database
  Future<void> _loadProducts() async {
    try {
      final products = await _dbHelper.getAllProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading products: $e');
    }
  }

  /// Load existing shopping list data for editing
  Future<void> _loadExistingListData() async {
    if (widget.existingList?.id == null) return;

    try {
      final existingItems = await _dbHelper.getShoppingListItems(
        widget.existingList!.id!,
      );

      if (mounted) {
        setState(() {
          _selectedProductIds.clear();
          _quantities.clear();

          for (final item in existingItems) {
            _selectedProductIds.add(item.productId);
            _quantities[item.productId] = item.quantity;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading existing list: $e');
    }
  }

  /// Validate form inputs
  bool _validateInputs({bool allowEmptyProducts = false}) {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a shopping list name', Colors.orange);
      return false;
    }

    if (!allowEmptyProducts && _selectedProductIds.isEmpty) {
      _showErrorSnackBar('Please select at least one product', Colors.orange);
      return false;
    }

    return true;
  }

  /// Save shopping list without starting shopping mode
  Future<void> _saveListOnly() async {
    // ✅ Allow saving empty lists (just validate the name)
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a shopping list name', Colors.orange);
      return;
    }

    try {
      final listId = await _saveShoppingListToDatabase();

      if (_selectedProductIds.isEmpty) {
        _showSuccessSnackBar(
          'Empty shopping list "${_nameController.text.trim()}" ${_isEditMode ? 'updated' : 'created'}!',
          showViewAction: true,
        );
      } else {
        _showSuccessSnackBar(
          _isEditMode
              ? 'Shopping list "${_nameController.text.trim()}" updated with ${_selectedProductIds.length} items!'
              : 'Shopping list "${_nameController.text.trim()}" saved with ${_selectedProductIds.length} items!',
          showViewAction: true,
        );
      }

      // Navigate back after delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Error saving shopping list: $e');
    }
  }

  /// Core method to save shopping list to database
  Future<int> _saveShoppingListToDatabase() async {
    int listId;

    if (_isEditMode) {
      // Update existing list
      final updatedList = widget.existingList!.copyWith(
        name: _nameController.text.trim(),
        isActive: true,
      );

      await _dbHelper.updateShoppingList(updatedList);
      listId = widget.existingList!.id!;

      // Clear existing items
      await _dbHelper.clearShoppingListItems(listId);
    } else {
      // Create new list
      final shoppingList = ShoppingList(
        name: _nameController.text.trim(),
        createdAt: DateTime.now(),
        isActive: true,
        items: [],
      );

      listId = await _dbHelper.insertShoppingList(shoppingList);
    }

    // Add selected products to the list
    for (final productId in _selectedProductIds) {
      final item = ShoppingListItem(
        shoppingListId: listId,
        productId: productId,
        quantity: _quantities[productId] ?? 1,
        isChecked: false,
      );
      await _dbHelper.insertShoppingListItem(item);
    }

    return listId;
  }

  /// Save empty shopping list (when allowEmpty is true)
  Future<void> _saveEmptyList() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a shopping list name');
      return;
    }

    try {
      final shoppingList = ShoppingList(
        name: _nameController.text.trim(),
        createdAt: DateTime.now(),
        isActive: true,
        items: [],
      );

      await _dbHelper.insertShoppingList(shoppingList);

      _showSuccessSnackBar(
        'Empty shopping list "${_nameController.text.trim()}" created!',
      );

      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error creating shopping list: $e');
    }
  }

  /// Toggle product selection
  void _toggleProduct(Product product) {
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
        _quantities.remove(product.id);
      } else {
        _selectedProductIds.add(product.id!);
        _quantities[product.id!] = 1;
      }
    });
  }

  /// Update product quantity
  void _updateQuantity(int productId, int quantity) {
    setState(() {
      _quantities[productId] = quantity;
    });
  }

  /// Show error snack bar
  void _showErrorSnackBar(String message, [Color? backgroundColor]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
      ),
    );
  }

  /// Show success snack bar
  void _showSuccessSnackBar(String message, {bool showViewAction = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        action: showViewAction
            ? SnackBarAction(
                label: 'VIEW LISTS',
                textColor: Colors.white,
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
    );
  }

  /// Build app bar - simplified without save action
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_isEditMode ? 'Edit Shopping List' : 'Create Shopping List'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      // ✅ Removed the actions - save button is now the FAB
    );
  }

  /// Build floating action button - now just for saving
  Widget? _buildFloatingActionButton() {
    // Only show save button when we have products selected OR we're editing
    if (_selectedProductIds.isEmpty && !_isEditMode) return null;

    return FloatingActionButton.extended(
      onPressed: _saveListOnly,
      backgroundColor: Colors.blue, // ✅ Changed to blue for "save"
      foregroundColor: Colors.white,
      icon: const Icon(Icons.save),
      label: Text(
        _isEditMode
            ? 'UPDATE LIST'
            : _selectedProductIds.isEmpty
            ? 'SAVE EMPTY LIST'
            : 'SAVE LIST (${_selectedProductIds.length})',
      ),
    );
  }

  /// Build name input field
  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Shopping List Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.shopping_cart),
        hintText: 'Enter a name for your shopping list',
      ),
      style: const TextStyle(fontSize: 16),
    );
  }

  /// Build section header with selection count
  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Select Products',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (_selectedProductIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100, // ✅ Changed to blue
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Text(
              '${_selectedProductIds.length} selected',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products first to create shopping lists',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build product list item
  Widget _buildProductItem(Product product, bool isSelected, int quantity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.green.shade50 : Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleProduct(product),
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child:
                      product.photoPath != null &&
                          File(product.photoPath!).existsSync()
                      ? Image.file(File(product.photoPath!), fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image,
                            color: Colors.grey.shade600,
                            size: 25,
                          ),
                        ),
                ),
              ),
            ],
          ),
          title: Text(
            product.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isSelected ? Colors.green.shade800 : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.category != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    product.category!,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                product.price != null
                    ? 'Price: €${product.price!.toStringAsFixed(2)}'
                    : 'Price: Not set',
                style: TextStyle(
                  color: product.price != null
                      ? Colors.green.shade600
                      : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Qty',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<int>(
                        value: quantity,
                        underline: const SizedBox(),
                        isDense: true,
                        items: List.generate(10, (i) => i + 1)
                            .map(
                              (qty) => DropdownMenuItem(
                                value: qty,
                                child: Text(
                                  '$qty',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (newQty) {
                          if (newQty != null) {
                            _updateQuantity(product.id!, newQty);
                          }
                        },
                      ),
                    ],
                  ),
                )
              : Icon(
                  Icons.add_circle_outline,
                  color: Colors.grey.shade400,
                  size: 28,
                ),
          onTap: () => _toggleProduct(product),
        ),
      ),
    );
  }

  /// Build widget tree
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List name input
            _buildNameInput(),

            const SizedBox(height: 24),

            // Section header with selection count
            _buildSectionHeader(),

            const SizedBox(height: 16),

            // Products list
            Expanded(
              child: _allProducts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _allProducts.length,
                      itemBuilder: (context, index) {
                        final product = _allProducts[index];
                        final isSelected = _selectedProductIds.contains(
                          product.id,
                        );
                        final quantity = _quantities[product.id] ?? 1;
                        return _buildProductItem(product, isSelected, quantity);
                      },
                    ),
            ),

            // ✅ Add helpful hint when no products selected
            if (_selectedProductIds.isEmpty && _allProducts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select products for your list, or save an empty list to add items later',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
