import 'package:flutter/material.dart';
import 'dart:io';
import '../product.dart';
import '../categories_helper.dart'; // Add this import
import 'screens/product_detail_page.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onDelete;
  final VoidCallback? onReplaceImage;
  final VoidCallback? onProductUpdated;

  const ProductCard({
    super.key,
    required this.product,
    this.onDelete,
    this.onReplaceImage,
    this.onProductUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                product: product,
                onProductUpdated: onProductUpdated,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Square image container
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  child:
                      product.photoPath != null &&
                          File(product.photoPath!).existsSync()
                      ? Image.file(
                          File(product.photoPath!),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (product.isFavorite)
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category - ADD THIS
                    if (product.category != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          ProductCategories.getDisplayName(product.category),
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    Text(
                      product.description.isNotEmpty
                          ? product.description
                          : 'No description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (product.price != null)
                      Text(
                        '€${product.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              // Menu button
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
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
                    value: 'replace_image',
                    child: Row(
                      children: [
                        Icon(Icons.photo_camera, size: 20),
                        SizedBox(width: 8),
                        Text('Replace Image'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
