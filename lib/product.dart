class Product {
  final int? id;
  final String name;
  final String description;
  final double? price;
  final String? photoPath;
  final bool isFavorite;

  Product({
    this.id,
    required this.name,
    required this.description,
    this.price,
    this.photoPath,
    this.isFavorite = false,
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
      'photoPath': photoPath,
      'isFavorite': isFavorite ? 1 : 0, // Convert bool to int for SQLite
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'] != null ? map['price'].toDouble() : null,
      photoPath: map['photoPath'],
      isFavorite: map['isFavorite'] == 1, // Convert int to bool
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? photoPath,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      photoPath: photoPath ?? this.photoPath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
