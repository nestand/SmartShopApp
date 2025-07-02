import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import '/db__helper.dart';
import 'product.dart';
import 'widgets/product_card.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/screens/product_form_page.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(SmartShopApp());
}

class SmartShopApp extends StatelessWidget {
  const SmartShopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Shop',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const ShoppingListPage(),
    );
  }
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ShoppingListPageState createState() => ShoppingListPageState();
}

class ShoppingListPageState extends State<ShoppingListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker(); // Add this line
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _dbHelper.getAllProducts();
    setState(() {
      _products = products;
    });
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
          // Create updated product with new image path
          final updatedProduct = product.copyWith(photoPath: picked.path);

          // Update in database
          await _dbHelper.updateProduct(updatedProduct);

          // Refresh the list
          await _loadProducts();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image updated for "${product.name}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Container()),
                ElevatedButton(
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
                  child: const Text('Add Product'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _products.isEmpty
                  ? const Center(child: Text('No products yet.'))
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (_, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          onDelete: () => _showDeleteConfirmation(product),
                          onReplaceImage: () => _replaceProductImage(product),
                          onProductUpdated:
                              _loadProducts, // This should refresh the list
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
