import 'product.dart';
import 'utils/database_utils.dart';

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

  /// Create ShoppingList from database map
  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: DatabaseUtils.safeInt(map['id']),
      name: DatabaseUtils.safeString(map['name']),
      createdAt: _parseCreatedAt(map['createdAt']), // Use helper method
      isActive: DatabaseUtils.safeBool(map['isActive'], defaultValue: true),
      items: const [],
    );
  }

  /// Helper method to parse createdAt from various formats
  static DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is int) {
      // Handle timestamp (milliseconds since epoch)
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      // Try to parse as int first (timestamp as string)
      final timestamp = int.tryParse(value);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      // Try to parse as ISO 8601 string
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date string: $value, error: $e');
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  /// Convert ShoppingList to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch, // Store as timestamp
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
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

  @override
  String toString() {
    return 'ShoppingList(id: $id, name: $name, createdAt: $createdAt, isActive: $isActive, items: ${items.length})';
  }
}

class ShoppingListItem {
  final int? id;
  final int shoppingListId;
  final int productId;
  final int quantity;
  final bool isChecked;
  final Product? product; // Optional product details

  const ShoppingListItem({
    this.id,
    required this.shoppingListId,
    required this.productId,
    this.quantity = 1,
    this.isChecked = false,
    this.product,
  });

  /// Create ShoppingListItem from database map
  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: DatabaseUtils.safeInt(map['id']),
      shoppingListId: DatabaseUtils.safeIntNotNull(map['shopping_list_id']),
      productId: DatabaseUtils.safeIntNotNull(map['product_id']),
      quantity: DatabaseUtils.safeIntNotNull(map['quantity'], defaultValue: 1),
      isChecked: DatabaseUtils.safeBool(map['isChecked']),
    );
  }

  /// Convert ShoppingListItem to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopping_list_id': shoppingListId,
      'product_id': productId,
      'quantity': quantity,
      'isChecked': isChecked ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
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

  @override
  String toString() {
    return 'ShoppingListItem(id: $id, shoppingListId: $shoppingListId, productId: $productId, quantity: $quantity, isChecked: $isChecked)';
  }
}
