// filepath: /home/kaban/Documents/SmartShopApp/lib/widgets/screens/product_management_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _dbHelper.getAllProducts();
    if (mounted) {
      setState(() {
        _products = products;
      });
    }
  }

  Future<void> _showDeleteConfirmation(Product product) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${product.name}"?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteProduct(product.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    await _dbHelper.deleteProduct(id);
    await _loadProducts();
  }

  Future<void> _replaceProductImage(Product product) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Replace image for "${product.name}"'),
        content: const Text('Choose how to get the new image:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        final picked = await _picker.pickImage(source: source);
        if (picked != null) {
          final updatedProduct = product.copyWith(photoPath: picked.path);
          await _dbHelper.updateProduct(updatedProduct);
          await _loadProducts();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image updated for "${product.name}"'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addProductToShoppingList(Product product) async {
    final lists = await _dbHelper.getAllShoppingLists();
    final activeLists = lists.where((list) => list.isActive).toList();

    if (activeLists.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active shopping lists. Create one first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;

    final selectedList = await showDialog<ShoppingList>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add "${product.name}" to list'),
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
                subtitle: Text('Created ${_formatDate(list.createdAt)}'),
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

    if (selectedList != null) {
      try {
        final existingItems = await _dbHelper.getShoppingListItems(
          selectedList.id!,
        );
        final alreadyExists = existingItems.any(
          (item) => item.productId == product.id,
        );

        if (alreadyExists) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${product.name} is already in ${selectedList.name}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        final item = ShoppingListItem(
          shoppingListId: selectedList.id!,
          productId: product.id!,
          quantity: 1,
        );

        await _dbHelper.insertShoppingListItem(item);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to ${selectedList.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductFormPage(
                    onSave: (newProduct) async {
                      await _dbHelper.insertProduct(newProduct);
                      await _loadProducts();
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _products.isEmpty
            ? const Center(
                child: Text('No products yet. Add your first product!'),
              )
            : ListView.builder(
                itemCount: _products.length,
                itemBuilder: (_, index) {
                  final product = _products[index];
                  return ProductCard(
                    product: product,
                    onDelete: () => _showDeleteConfirmation(product),
                    onReplaceImage: () => _replaceProductImage(product),
                    onProductUpdated: _loadProducts,
                    onAddToList: () => _addProductToShoppingList(product),
                  );
                },
              ),
      ),
    );
  }
}
