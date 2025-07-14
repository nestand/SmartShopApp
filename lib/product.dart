import 'utils/database_utils.dart';

class Product {
  final int? id;
  final String name;
  final String description;
  final double? price;
  final String? category;
  final String? photoPath;
  final bool isFavorite;

  const Product({
    this.id,
    required this.name,
    this.description = '',
    this.price,
    this.category,
    this.photoPath,
    this.isFavorite = false,
  });

  /// Create Product from database map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: DatabaseUtils.safeInt(map['id']),
      name: DatabaseUtils.safeString(map['name']),
      description: DatabaseUtils.safeString(map['description']),
      price: DatabaseUtils.safeDouble(map['price']),
      category: map['category'] as String?,
      photoPath: map['photoPath'] as String?,
      isFavorite: DatabaseUtils.safeBool(map['isFavorite']),
    );
  }

  /// Convert Product to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'photoPath': photoPath,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? photoPath,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      photoPath: photoPath ?? this.photoPath,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, description: $description, price: $price, category: $category, photoPath: $photoPath, isFavorite: $isFavorite)';
  }
}
