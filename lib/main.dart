import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import '/db__helper.dart';
import 'product.dart';
import 'shopping_list.dart';
import 'widgets/product_card.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/screens/product_form_page.dart';
import 'widgets/shopping_list_creation_page.dart';
import 'widgets/shopping_mode_page.dart';
import 'widgets/screens/product_management_page.dart'; // new widget

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
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
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MainPage(),
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

  Future<void> _continueShoppingList(ShoppingList shoppingList) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingModePage(shoppingListId: shoppingList.id!),
      ),
    );
    await _loadData();
  }

  Future<void> _editShoppingList(ShoppingList shoppingList) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListCreationPage(existingList: shoppingList),
      ),
    );
    await _loadData();
  }

  Future<void> _deleteShoppingList(ShoppingList shoppingList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${shoppingList.name}"?'),
        content: const Text(
          'This will delete the shopping list and all its items.',
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
      await _dbHelper.deleteShoppingList(shoppingList.id!);
      await _loadData();
    }
  }

  // Add this method to _MainPageState class for debugging:
  Future<void> _debugDatabase() async {
    try {
      final stats = await _dbHelper.getDatabaseStats();
      final products = await _dbHelper.getAllProducts();

      print('=== DATABASE DEBUG ===');
      print('Products in DB: ${stats['products']}');
      print('Shopping Lists in DB: ${stats['shopping_lists']}');
      print('Items in DB: ${stats['shopping_list_items']}');
      print('Products list: ${products.map((p) => p.name).toList()}');
      print('===================');

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Database Debug'),
            content: Text(
              'Products: ${stats['products']}\n'
              'Shopping Lists: ${stats['shopping_lists']}\n'
              'Items: ${stats['shopping_list_items']}\n\n'
              'Product names:\n${products.map((p) => '• ${p.name}').join('\n')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Database debug error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Temporary test method to add a product
  Future<void> _testAddProduct() async {
    try {
      print('Testing product insertion...');

      final testProduct = Product(
        name: 'Test Product ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test product',
        price: 9.99,
        category: 'Test Category',
        // ✅ Don't include quantity here - that's for ShoppingListItem
      );

      print('Product to insert: ${testProduct.toMap()}');

      final id = await _dbHelper.insertProduct(testProduct);
      print('Product inserted with ID: $id');

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test product added with ID: $id'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error inserting test product: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
          // Add test product button
          IconButton(
            onPressed: _testAddProduct,
            icon: const Icon(Icons.add),
            tooltip: 'Test Add Product',
          ),
          // Debug button
          IconButton(
            onPressed: _debugDatabase,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Database',
          ),
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
                                // Quick "Start Shopping" button
                                IconButton(
                                  onPressed: () =>
                                      _continueShoppingList(shoppingList),
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.green,
                                  ),
                                  tooltip: 'Start Shopping',
                                ),
                                // More options menu
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editShoppingList(shoppingList);
                                        break;
                                      case 'delete':
                                        _deleteShoppingList(shoppingList);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Edit List'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _continueShoppingList(
                              shoppingList,
                            ), // Default action: start shopping
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
