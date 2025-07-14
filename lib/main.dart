import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import '/db__helper.dart';
import 'product.dart';
import 'shopping_list.dart';
import 'widgets/shopping_list_creation_page.dart';
import 'widgets/shopping_mode_page.dart';
import 'widgets/screens/product_management_page.dart';
import 'widgets/screens/product_form_page.dart';

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
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load data with proper error handling
  Future<void> _loadData() async {
    if (!mounted) return; // Fix: Early exit if unmounted

    try {
      setState(() {
        _isLoading = true;
      });

      final lists = await _dbHelper.getAllShoppingLists();
      final products = await _dbHelper.getAllProducts();

      if (mounted) {
        // Check before setState
        setState(() {
          _shoppingLists = lists;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        // Check before setState
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading data: $e');
      }
    }
  }

  /// Create new shopping list with proper navigation handling
  Future<void> _createNewShoppingList() async {
    if (!mounted) return; // Early exit if unmounted

    if (_products.isEmpty) {
      final choice = await _showNoProductsDialog();
      if (!mounted) return; // Check after dialog

      switch (choice) {
        case 'add_products':
          await _navigateToProductManagement();
          break;
        case 'create_empty':
          await _navigateToCreateEmptyList();
          break;
        default:
          return;
      }
    } else {
      await _navigateToCreateList();
    }
  }

  /// Show no products dialog
  Future<String?> _showNoProductsDialog() async {
    if (!mounted) return null;

    return await showDialog<String>(
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
  }

  /// Navigate to product management
  Future<void> _navigateToProductManagement() async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductManagementPage()),
      );
      if (mounted) await _loadData(); // Check before reload
    } catch (e) {
      debugPrint('Error navigating to product management: $e');
      if (mounted) _showErrorSnackBar('Navigation error: $e');
    }
  }

  /// Navigate to create empty list
  Future<void> _navigateToCreateEmptyList() async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ShoppingListCreationPage(allowEmpty: true),
        ),
      );
      if (mounted) await _loadData(); // Check before reload
    } catch (e) {
      debugPrint('Error creating empty list: $e');
      if (mounted) _showErrorSnackBar('Error creating empty list: $e');
    }
  }

  /// Navigate to create list
  Future<void> _navigateToCreateList() async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingListCreationPage()),
      );
      if (mounted) await _loadData(); // Check before reload
    } catch (e) {
      debugPrint('Error creating list: $e');
      if (mounted) _showErrorSnackBar('Error creating list: $e');
    }
  }

  /// Edit an existing shopping list
  Future<void> _editShoppingList(ShoppingList shoppingList) async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingListCreationPage(existingList: shoppingList),
        ),
      );
      if (mounted) await _loadData(); // Check before reload
    } catch (e) {
      debugPrint('Error editing shopping list: $e');
      if (mounted) _showErrorSnackBar('Error editing list: $e');
    }
  }

  /// Start shopping with an existing list
  Future<void> _startShopping(ShoppingList shoppingList) async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingModePage(shoppingListId: shoppingList.id!),
        ),
      );
      if (mounted) await _loadData(); // Check before reload
    } catch (e) {
      debugPrint('Error starting shopping: $e');
      if (mounted) _showErrorSnackBar('Error starting shopping: $e');
    }
  }

  /// Delete a shopping list with confirmation
  Future<void> _deleteShoppingList(ShoppingList shoppingList) async {
    if (!mounted) return;

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

    if (!mounted) return; // Check after dialog

    if (confirmed == true) {
      try {
        await _dbHelper.deleteShoppingList(shoppingList.id!);
        if (mounted) await _loadData(); // Check before reload

        if (mounted) {
          // Check before showing snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shopping list "${shoppingList.name}" deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting shopping list: $e');
        if (mounted) _showErrorSnackBar('Error deleting list: $e');
      }
    }
  }

  /// Show error snackbar safely
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigate to product management from app bar
  Future<void> _navigateToProductManagementFromAppBar() async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductManagementPage()),
      );
      if (mounted) await _loadData(); // Check before reload
    } catch (e) {
      debugPrint('Error navigating to product management: $e');
      if (mounted) _showErrorSnackBar('Navigation error: $e');
    }
  }

  /// Navigate to add a new product directly
  Future<void> _navigateToAddProduct() async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFormPage(
            onSave: (Product newProduct) async {
              try {
                await _dbHelper.insertProduct(newProduct);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Product "${newProduct.name}" added successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error saving product: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
      if (mounted) await _loadData(); // Refresh data after adding product
    } catch (e) {
      debugPrint('Error navigating to add product: $e');
      if (mounted) _showErrorSnackBar('Error opening product form: $e');
    }
  }

  /// Show database statistics
  Future<void> _showDatabaseStats() async {
    if (!mounted) return;

    try {
      final stats = await _dbHelper.getDatabaseStats();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Database Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Products', stats['products'] ?? 0),
              _buildStatRow('Shopping Lists', stats['shopping_lists'] ?? 0),
              _buildStatRow('List Items', stats['shopping_list_items'] ?? 0),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      if (mounted) _showErrorSnackBar('Error loading statistics: $e');
    }
  }

  /// Build a statistics row
  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final activeLists = _shoppingLists.where((list) => list.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Shop'),
        actions: [
          // Add a menu with more options
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'manage_products':
                  await _navigateToProductManagementFromAppBar();
                  break;
                case 'add_product':
                  await _navigateToAddProduct();
                  break;
                case 'view_stats':
                  await _showDatabaseStats();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'manage_products',
                child: Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Manage Products'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add_product',
                child: Row(
                  children: [
                    Icon(Icons.add_box, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Add New Product'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('View Statistics'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your shopping lists...'),
                ],
              ),
            )
          : Padding(
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

                  const SizedBox(height: 12), // Add spacing
                  // Add quick access row for common actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToProductManagementFromAppBar,
                          icon: const Icon(Icons.inventory, size: 18),
                          label: const Text('Manage Products'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToAddProduct,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Product'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Active shopping lists section
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Your Shopping Lists',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
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
                        : RefreshIndicator(
                            onRefresh: _loadData, // Pull to refresh
                            child: ListView.builder(
                              itemCount: activeLists.length,
                              itemBuilder: (_, index) {
                                final shoppingList = activeLists[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
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
                                          onPressed: () =>
                                              _startShopping(shoppingList),
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
                                    onTap: () => _startShopping(shoppingList),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
