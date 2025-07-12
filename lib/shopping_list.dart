import 'product.dart';

//new calss to handle two modes correctly
class ShoppingList {
  final int? id;
  final String name;
  final DateTime createdAt;
  final bool isActive;
  final List<ShoppingListItem> items;

  const ShoppingList({
    this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isActive: map['isActive'] == 1,
      items: [], // Will be loaded separately
    );
  }

  // Add copyWith method
  ShoppingList copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
    List<ShoppingListItem>? items,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      items: items ?? this.items,
    );
  }
}

class ShoppingListItem {
  final int? id;
  final int shoppingListId;
  final int productId;
  final int quantity; // ✅ Quantity belongs here
  final bool isChecked;
  final Product? product;

  ShoppingListItem({
    this.id,
    required this.shoppingListId,
    required this.productId,
    this.quantity = 1,
    this.isChecked = false,
    this.product,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'product_id': productId,
      'quantity': quantity,
      'isChecked': isChecked ? 1 : 0, // Convert bool to int for SQLite
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      shoppingListId: map['shopping_list_id'],
      productId: map['product_id'],
      quantity: map['quantity'] ?? 1,
      isChecked: map['isChecked'] == 1, // Convert int back to bool
    );
  }

  // Add copyWith method
  ShoppingListItem copyWith({
    int? id,
    int? shoppingListId,
    int? productId,
    int? quantity,
    bool? isChecked,
    Product? product,
  }) {
    return ShoppingListItem(
      id: id ?? this.id,
      shoppingListId: shoppingListId ?? this.shoppingListId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
      product: product ?? this.product,
    );
  }
}
