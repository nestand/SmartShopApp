import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import '/db__helper.dart';
import 'product.dart';
import 'widgets/product_card.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(SmartShopApp());
}

class SmartShopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Shop',
      theme: ThemeData(primarySwatch: Colors.green),
      home: ShoppingListPage(),
    );
  }
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({Key? key}) : super(key: key);

  @override
  ShoppingListPageState createState() => ShoppingListPageState();
}

class ShoppingListPageState extends State<ShoppingListPage> {
  final TextEditingController _controller = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

  Future<void> _addProduct() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose where to pick the product image from.'),
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

    String? imagePath;

    if (source != null) {
      try {
        final picked = await picker.pickImage(source: source);
        if (picked != null) {
          imagePath = picked.path;
          print('Image picked: $imagePath');
        }
      } catch (e) {
        print('Error picking image: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }

    final newProduct = Product(
      name: text,
      description: 'No description yet',
      price: null,
      photoPath: imagePath,
    );

    try {
      await _dbHelper.insertProduct(newProduct);
      _controller.clear();
      await _loadProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product "${newProduct.name}" added successfully!'),
        ),
      );
    } catch (e) {
      print('Error inserting product: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding product: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Shop')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: _addProduct, child: Text('Add')),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: _products.isEmpty
                  ? Center(child: Text('No products yet.'))
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (_, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          onDelete: () => _showDeleteConfirmation(product),
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
