class Product {
  final int? id;
  final String name;
  final String description;
  final double? price;
  final String? photoPath;
  final String? category;
  final bool isFavorite; // ✅ Add this field

  Product({
    this.id,
    required this.name,
    required this.description,
    this.price,
    this.photoPath,
    this.category,
    this.isFavorite = false, // ✅ Add this parameter with default value
  });

  // Default img
  String get displayPhotoPath {
    return photoPath ?? 'assets/images/default_product.png';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'photoPath': photoPath,
      'isFavorite': isFavorite ? 1 : 0, // ✅ Keep this line
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '', // ✅ Add default empty string
      price: map['price']?.toDouble(),
      category: map['category'],
      photoPath: map['photoPath'],
      isFavorite: map['isFavorite'] == 1, // ✅ Keep this line
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? photoPath,
    bool? isFavorite, // ✅ Keep this parameter
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      photoPath: photoPath ?? this.photoPath,
      isFavorite: isFavorite ?? this.isFavorite, // ✅ Keep this line
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, description: $description, price: $price, category: $category, photoPath: $photoPath, isFavorite: $isFavorite}';
  }
}
