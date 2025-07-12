import 'package:flutter/material.dart';
import 'dart:io';
import '../product.dart';
import '../categories_helper.dart';
import 'screens/product_detail_page.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onDelete;
  final VoidCallback? onReplaceImage;
  final VoidCallback? onProductUpdated;
  final VoidCallback? onAddToList;
  final VoidCallback? onToggleFavorite; // ✅ Add this

  const ProductCard({
    super.key,
    required this.product,
    this.onDelete,
    this.onReplaceImage,
    this.onProductUpdated,
    this.onAddToList,
    this.onToggleFavorite, // ✅ Add this
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child:
                    product.photoPath != null &&
                        File(product.photoPath!).existsSync()
                    ? Image.file(File(product.photoPath!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // ✅ Add favorite icon
                      IconButton(
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          product.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.isFavorite ? Colors.red : Colors.grey,
                        ),
                        tooltip: product.isFavorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                      ),
                    ],
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  if (product.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Price: €${product.price!.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'add_to_list':
                    onAddToList?.call();
                    break;
                  case 'replace_image':
                    onReplaceImage?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_to_list',
                  child: Row(
                    children: [
                      Icon(Icons.add_shopping_cart, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Add to List'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'replace_image',
                  child: Row(
                    children: [
                      Icon(Icons.image, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Replace Image'),
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
      ),
    );
  }
}
