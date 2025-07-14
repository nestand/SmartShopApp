import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../product.dart';
import '../../shopping_list.dart';
import '../../db__helper.dart';
import '../product_card.dart';
import 'product_form_page.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// Load all products from database
  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final products = await _dbHelper.getAllProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Error loading products: $e');
      }
    }
  }

  /// Navigate to product form for adding new product
  Future<void> _addNewProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(onSave: _handleProductSave),
      ),
    );
  }

  /// Handle saving new product
  Future<void> _handleProductSave(Product newProduct) async {
    try {
      await _dbHelper.insertProduct(newProduct);
      await _loadProducts();
      _showSuccessMessage('Product "${newProduct.name}" added successfully!');
    } catch (e) {
      _showErrorMessage('Error saving product: $e');
    }
  }

  /// Handle updating existing product
  Future<void> _handleProductUpdate(Product updatedProduct) async {
    try {
      print('=== HANDLE PRODUCT UPDATE DEBUG ===');
      print('Updated product: ${updatedProduct.toMap()}');

      await _dbHelper.updateProduct(updatedProduct);
      await _loadProducts();

      print('Product updated successfully in UI');
      print('===================================');

      _showSuccessMessage(
        'Product "${updatedProduct.name}" updated successfully!',
      );
    } catch (e) {
      print('Error in _handleProductUpdate: $e');
      _showErrorMessage('Error updating product: $e');
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${product.name}"?'),
        content: const Text(
          'This action cannot be undone. The product will also be removed from all shopping lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteProduct(product);
    }
  }

  /// Delete product from database
  Future<void> _deleteProduct(Product product) async {
    try {
      await _dbHelper.deleteProduct(product.id!);
      await _loadProducts();
      _showSuccessMessage('Product "${product.name}" deleted successfully!');
    } catch (e) {
      _showErrorMessage('Error deleting product: $e');
    }
  }

  /// Show image source selection dialog and update product image
  Future<void> _replaceProductImage(Product product) async {
    final source = await _showImageSourceDialog(product.name);
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        final updatedProduct = product.copyWith(photoPath: picked.path);
        await _dbHelper.updateProduct(updatedProduct);
        await _loadProducts();
        _showSuccessMessage('Image updated for "${product.name}"');
      }
    } catch (e) {
      _showErrorMessage('Error updating image: $e');
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog(String productName) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Replace image for "$productName"'),
        content: const Text('Choose how to get the new image:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt),
                SizedBox(width: 8),
                Text('Camera'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library),
                SizedBox(width: 8),
                Text('Gallery'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Toggle product favorite status
  Future<void> _toggleProductFavorite(Product product) async {
    try {
      await _dbHelper.toggleProductFavorite(product.id!);
      await _loadProducts();

      _showSuccessMessage(
        product.isFavorite
            ? '${product.name} removed from favorites'
            : '${product.name} added to favorites',
        backgroundColor: Colors.blue,
      );
    } catch (e) {
      _showErrorMessage('Error updating favorite: $e');
    }
  }

  /// Show dialog to select shopping list and add product
  Future<void> _addProductToShoppingList(Product product) async {
    try {
      final lists = await _dbHelper.getAllShoppingLists();
      final activeLists = lists.where((list) => list.isActive).toList();

      if (activeLists.isEmpty) {
        _showErrorMessage(
          'No active shopping lists. Create one first!',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final selectedList = await _showShoppingListSelectionDialog(
        product.name,
        activeLists,
      );

      if (selectedList != null) {
        await _addToSelectedList(product, selectedList);
      }
    } catch (e) {
      _showErrorMessage('Error loading shopping lists: $e');
    }
  }

  /// Show shopping list selection dialog
  Future<ShoppingList?> _showShoppingListSelectionDialog(
    String productName,
    List<ShoppingList> activeLists,
  ) async {
    return await showDialog<ShoppingList>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add "$productName" to list'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: activeLists.length,
            itemBuilder: (_, index) {
              final list = activeLists[index];
              return ListTile(
                leading: Icon(
                  Icons.shopping_cart,
                  color: Colors.green.shade600,
                ),
                title: Text(list.name),
                subtitle: Text(
                  'Created ${_formatDate(list.createdAt)} • ${list.items.length} items',
                ),
                onTap: () => Navigator.pop(ctx, list),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Add product to selected shopping list
  Future<void> _addToSelectedList(
    Product product,
    ShoppingList selectedList,
  ) async {
    try {
      final existingItems = await _dbHelper.getShoppingListItems(
        selectedList.id!,
      );
      final alreadyExists = existingItems.any(
        (item) => item.productId == product.id,
      );

      if (alreadyExists) {
        _showErrorMessage(
          '${product.name} is already in ${selectedList.name}',
          backgroundColor: Colors.orange,
        );
        return;
      }

      final item = ShoppingListItem(
        shoppingListId: selectedList.id!,
        productId: product.id!,
        quantity: 1,
        isChecked: false,
      );

      await _dbHelper.insertShoppingListItem(item);
      _showSuccessMessage('${product.name} added to ${selectedList.name}');
    } catch (e) {
      _showErrorMessage('Error adding product to list: $e');
    }
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

  /// Show success message
  void _showSuccessMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Manage Products'),
      elevation: 2,
      actions: [
        IconButton(
          onPressed: _addNewProduct,
          icon: const Icon(Icons.add),
          tooltip: 'Add Product',
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'refresh':
                await _loadProducts();
                break;
              case 'favorites':
                await _showFavoriteProducts();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'favorites',
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red),
                  SizedBox(width: 8),
                  Text('View Favorites'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Show favorite products in dialog
  Future<void> _showFavoriteProducts() async {
    final favoriteProducts = _products.where((p) => p.isFavorite).toList();

    if (favoriteProducts.isEmpty) {
      _showErrorMessage(
        'No favorite products yet!',
        backgroundColor: Colors.orange,
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Favorite Products (${favoriteProducts.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: favoriteProducts.length,
            itemBuilder: (_, index) {
              final product = favoriteProducts[index];
              return ListTile(
                leading: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
                title: Text(product.name),
                subtitle: product.category != null
                    ? Text(product.category!)
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
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
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first product to get started!',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _addNewProduct,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading products...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  /// Edit an existing product
  Future<void> _editProduct(Product product) async {
    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProductFormPage(existing: product, onSave: _handleProductUpdate),
        ),
      );
      if (mounted) await _loadProducts();
    } catch (e) {
      debugPrint('Error editing product: $e');
      if (mounted) _showErrorMessage('Error editing product: $e');
    }
  }

  /// Build products list
  Widget _buildProductsList() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (_, index) {
          final product = _products[index];
          return ProductCard(
            product: product,
            onEdit: () => _editProduct(product),
            onDelete: () => _showDeleteConfirmation(product),
            onReplaceImage: () => _replaceProductImage(product),
            onProductUpdated: _loadProducts,
            onAddToList: () => _addProductToShoppingList(product),
            onToggleFavorite: () => _toggleProductFavorite(product),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _products.isEmpty
          ? _buildEmptyState()
          : _buildProductsList(),
    );
  }
}
