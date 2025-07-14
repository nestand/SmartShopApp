import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'product.dart';
import 'db__helper.dart';

class ProductFormPage extends StatefulWidget {
  final Product? existing;
  final Function(Product) onSave;

  const ProductFormPage({super.key, this.existing, required this.onSave});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  String? _photoPath;
  bool _isFavorite = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditMode => widget.existing != null;

  String? _selectedCategory;

  final List<String> _categories = [
    'Bakery',
    'Dairy',
    'Meat',
    'Vegetables',
    'Fruits',
    'Beverages',
    'Snacks',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final product = widget.existing!;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price?.toString() ?? '';
      _categoryController.text = product.category ?? '';
      _photoPath = product.photoPath;
      _isFavorite = product.isFavorite;

      _selectedCategory = product.category;
      if (_selectedCategory != null &&
          !_categories.contains(_selectedCategory)) {
        _categories.add(_selectedCategory!);
      }
    }
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose how to get the image:'),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source != null) {
      try {
        final picked = await _picker.pickImage(source: source);
        if (picked != null) {
          setState(() {
            _photoPath = picked.path;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final product = Product(
        id: widget.existing?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        photoPath: _photoPath,
        isFavorite: _isFavorite,
      );

      // ✅ Use callback if provided
      await widget.onSave!(product);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Product' : 'Add Product'),
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _photoPath != null && File(_photoPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_photoPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Price field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Favorite toggle
              CheckboxListTile(
                title: const Text('Mark as Favorite'),
                subtitle: const Text('Add this product to your favorites'),
                value: _isFavorite,
                onChanged: (value) {
                  setState(() {
                    _isFavorite = value ?? false;
                  });
                },
                secondary: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
