import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import '/db__helper.dart';
import 'product.dart';
import 'shopping_list.dart';
import 'widgets/shopping_list_creation_page.dart';
import 'widgets/shopping_mode_page.dart';
import 'widgets/screens/product_management_page.dart';

void main() {
  // Initialize SQLite FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize sqflite FFI
    sqfliteFfiInit();
    // Set the database factory to use FFI
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const SmartShopApp());
}

class SmartShopApp extends StatelessWidget {
  const SmartShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Shop',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true, // Enable Material 3
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ShoppingList> _shoppingLists = [];
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final lists = await _dbHelper.getAllShoppingLists();
    final products = await _dbHelper.getAllProducts();

    if (mounted) {
      setState(() {
        _shoppingLists = lists;
        _products = products;
      });
    }
  }

  Future<void> _createNewShoppingList() async {
    if (_products.isEmpty) {
      if (!mounted) return;

      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Products Available'),
          content: const Text(
            'You don\'t have any products yet. What would you like to do?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'add_products'),
              child: const Text('Add Products First'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'create_empty'),
              child: const Text('Create Empty List'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (choice == 'add_products') {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductManagementPage()),
        );
        await _loadData();
        return;
      } else if (choice == 'create_empty') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ShoppingListCreationPage(allowEmpty: true),
          ),
        );
        await _loadData();
        return;
      } else {
        return;
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShoppingListCreationPage()),
    );

    await _loadData();
  }

  /// Edit an existing shopping list
  Future<void> _editShoppingList(ShoppingList shoppingList) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListCreationPage(existingList: shoppingList),
      ),
    );
    await _loadData(); // Refresh the data
  }

  /// Start shopping with an existing list
  Future<void> _startShopping(ShoppingList shoppingList) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingModePage(shoppingListId: shoppingList.id!),
      ),
    );
    await _loadData(); // Refresh the data
  }

  /// Delete a shopping list with confirmation
  Future<void> _deleteShoppingList(ShoppingList shoppingList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${shoppingList.name}"?'),
        content: const Text(
          'This action cannot be undone. All items in this list will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteShoppingList(shoppingList.id!);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shopping list "${shoppingList.name}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting list: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLists = _shoppingLists.where((list) => list.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Shop'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductManagementPage(),
                ),
              );
              await _loadData();
            },
            icon: const Icon(Icons.inventory),
            tooltip: 'Manage Products',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create new shopping list button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createNewShoppingList,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Create New Shopping List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Active shopping lists section
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Your Shopping Lists',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Shopping lists
            Expanded(
              child: activeLists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shopping lists yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first shopping list to get started!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeLists.length,
                      itemBuilder: (_, index) {
                        final shoppingList = activeLists[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                Icons.shopping_cart,
                                color: Colors.green.shade700,
                              ),
                            ),
                            title: Text(
                              shoppingList.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Created ${_formatDate(shoppingList.createdAt)} • ${shoppingList.items.length} items',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit list button
                                IconButton(
                                  onPressed: () =>
                                      _editShoppingList(shoppingList),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Edit List',
                                ),
                                // Start shopping button
                                IconButton(
                                  onPressed: () => _startShopping(shoppingList),
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.green,
                                  ),
                                  tooltip: 'Start Shopping',
                                ),
                                // Delete button
                                IconButton(
                                  onPressed: () =>
                                      _deleteShoppingList(shoppingList),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Delete List',
                                ),
                              ],
                            ),
                            onTap: () =>
                                _startShopping(shoppingList), // ✅ Fixed
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
