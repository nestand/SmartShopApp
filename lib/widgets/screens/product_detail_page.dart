import 'package:flutter/material.dart';
import 'dart:io';
import '../../product.dart';
import '../../db__helper.dart';
import 'package:image_picker/image_picker.dart';
import 'product_form_page.dart';
import '../../categories_helper.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final VoidCallback? onProductUpdated;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.onProductUpdated,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product _currentProduct;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
  }

  Future<void> _replaceImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Replace image for "${_currentProduct.name}"'),
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
          final updatedProduct = _currentProduct.copyWith(
            photoPath: picked.path,
          );
          await DatabaseHelper.instance.updateProduct(updatedProduct);

          setState(() {
            _currentProduct = updatedProduct;
          });

          widget.onProductUpdated?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image updated for "${_currentProduct.name}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final updatedProduct = _currentProduct.copyWith(
      isFavorite: !_currentProduct.isFavorite,
    );

    await DatabaseHelper.instance.updateProduct(updatedProduct);

    setState(() {
      _currentProduct = updatedProduct;
    });

    widget.onProductUpdated?.call();
  }

  Future<void> _editProduct() async {
    final result = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormPage(
          existing: _currentProduct,
          onSave: (updatedProduct) async {
            // This will be called when Save is pressed
            await DatabaseHelper.instance.updateProduct(updatedProduct);

            // Update local state
            setState(() {
              _currentProduct = updatedProduct;
            });

            // Refresh the main list
            widget.onProductUpdated?.call();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Product "${updatedProduct.name}" updated successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentProduct.name),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _currentProduct.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _currentProduct.isFavorite ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Product Image
            Center(
              child: GestureDetector(
                onTap: _replaceImage,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _currentProduct.photoPath != null &&
                            File(_currentProduct.photoPath!).existsSync()
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_currentProduct.photoPath!),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add photo',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Product Details Card - SAME WIDTH AS IMAGE
            Container(
              width: double.infinity, // This makes it full width like the image
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      'Product Name',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentProduct.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 16),

                    // Category - NEW
                    Text(
                      'Category',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        ProductCategories.getDisplayName(
                          _currentProduct.category,
                        ),
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Description',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentProduct.description.isNotEmpty
                          ? _currentProduct.description
                          : 'No description available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 16),

                    // Price
                    Text(
                      'Price',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentProduct.price != null
                          ? '€${_currentProduct.price!.toStringAsFixed(2)}'
                          : 'Price not set',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _currentProduct.price != null
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons - SAME WIDTH AS IMAGE AND CARD
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _replaceImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Change Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editProduct,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
