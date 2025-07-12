import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // Add this for debugPrint
import 'product.dart';
import 'shopping_list.dart';

class DatabaseHelper {
  static const _databaseName = "SmartShop.db";
  static const _databaseVersion = 3; // ✅ Increment version to 3

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL,
        category TEXT,
        photoPath TEXT,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create shopping_lists table
    await db.execute('''
      CREATE TABLE shopping_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create shopping_list_items table
    await db.execute('''
      CREATE TABLE shopping_list_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopping_list_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        isChecked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add isChecked column if upgrading from version 1
      try {
        await db.execute('''
          ALTER TABLE shopping_list_items 
          ADD COLUMN isChecked INTEGER DEFAULT 0
        ''');
      } catch (e) {
        debugPrint('Column isChecked might already exist: $e');
      }
    }

    if (oldVersion < 3) {
      // Add isFavorite column to products table
      try {
        await db.execute('''
          ALTER TABLE products 
          ADD COLUMN isFavorite INTEGER DEFAULT 0
        ''');
      } catch (e) {
        debugPrint('Column isFavorite might already exist: $e');
      }
    }
  }

  // Product methods
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  // Shopping List methods
  Future<int> insertShoppingList(ShoppingList shoppingList) async {
    final db = await database;
    return await db.insert('shopping_lists', shoppingList.toMap());
  }

  Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await database;
    final result = await db.query('shopping_lists', orderBy: 'createdAt DESC');

    List<ShoppingList> lists = [];
    for (var listMap in result) {
      final shoppingList = ShoppingList.fromMap(listMap);
      // Load items for each shopping list
      final items = await getShoppingListItems(shoppingList.id!);
      lists.add(shoppingList.copyWith(items: items));
    }

    return lists;
  }

  Future<int> updateShoppingList(ShoppingList shoppingList) async {
    final db = await database;
    return await db.update(
      'shopping_lists',
      shoppingList.toMap(),
      where: 'id = ?',
      whereArgs: [shoppingList.id],
    );
  }

  Future<int> deleteShoppingList(int id) async {
    final db = await database;
    // Delete items first (cascade should handle this, but let's be explicit)
    await db.delete(
      'shopping_list_items',
      where: 'shopping_list_id = ?',
      whereArgs: [id],
    );
    // Then delete the shopping list
    return await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  // Shopping List Items methods
  Future<int> insertShoppingListItem(ShoppingListItem item) async {
    final db = await database;
    return await db.insert('shopping_list_items', item.toMap());
  }

  Future<List<ShoppingListItem>> getShoppingListItems(
    int shoppingListId,
  ) async {
    final db = await database;
    final result = await db.query(
      'shopping_list_items',
      where: 'shopping_list_id = ?',
      whereArgs: [shoppingListId],
    );
    return result.map((json) => ShoppingListItem.fromMap(json)).toList();
  }

  Future<List<ShoppingListItem>> getShoppingListItemsWithProduct(
    int shoppingListId,
  ) async {
    final db = await database;
    final result = await db.query(
      'shopping_list_items',
      where: 'shopping_list_id = ?',
      whereArgs: [shoppingListId], // ✅ Fixed: Added missing whereArgs
    );

    List<ShoppingListItem> items = [];
    for (var itemMap in result) {
      final item = ShoppingListItem.fromMap(itemMap);
      final product = await getProduct(item.productId);
      items.add(item.copyWith(product: product));
    }

    return items;
  }

  Future<int> updateShoppingListItem(ShoppingListItem item) async {
    final db = await database;
    return await db.update(
      'shopping_list_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteShoppingListItem(int id) async {
    final db = await database;
    return await db.delete(
      'shopping_list_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearShoppingListItems(int shoppingListId) async {
    final db = await database;
    await db.delete(
      'shopping_list_items',
      where: 'shopping_list_id = ?',
      whereArgs: [shoppingListId],
    );
  }

  // Add method to toggle favorite status
  Future<int> toggleProductFavorite(int productId) async {
    final db = await database;
    final product = await getProduct(productId);
    if (product != null) {
      final updatedProduct = product.copyWith(isFavorite: !product.isFavorite);
      return await updateProduct(updatedProduct);
    }
    return 0;
  }

  // Add method to get favorite products
  Future<List<Product>> getFavoriteProducts() async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  // Utility methods
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Debug method to check database status
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final productsCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products',
    );
    final listsCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM shopping_lists',
    );
    final itemsCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM shopping_list_items',
    );

    return {
      'products': productsCount.first['count'] as int,
      'shopping_lists': listsCount.first['count'] as int,
      'shopping_list_items': itemsCount.first['count'] as int,
    };
  }
}
