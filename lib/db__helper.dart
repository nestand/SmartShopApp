import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'product.dart';
import 'shopping_list.dart';

class DatabaseHelper {
  static const _databaseName = "SmartShop.db";
  static const _databaseVersion = 3;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  /// Configure database (enable foreign keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all database tables
  Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // Create products table
      await txn.execute('''
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
      await txn.execute('''
        CREATE TABLE shopping_lists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Create shopping_list_items table
      await txn.execute('''
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
    });
  }

  /// Handle database schema upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      if (oldVersion < 2) {
        // Add isChecked column if upgrading from version 1
        try {
          await txn.execute('''
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
          await txn.execute('''
            ALTER TABLE products 
            ADD COLUMN isFavorite INTEGER DEFAULT 0
          ''');
        } catch (e) {
          debugPrint('Column isFavorite might already exist: $e');
        }
      }
    });
  }

  // ==================== PRODUCT METHODS ====================

  /// Insert a new product
  Future<int> insertProduct(Product product) async {
    try {
      final db = await database;
      final id = await db.insert('products', product.toMap());
      debugPrint('Product inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting product: $e');
      rethrow;
    }
  }

  /// Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final db = await database;
      final result = await db.query('products', orderBy: 'name ASC');
      return result.map((json) => Product.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error getting all products: $e');
      rethrow;
    }
  }

  /// Get a single product by ID
  Future<Product?> getProduct(int id) async {
    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return Product.fromMap(result.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product with ID $id: $e');
      return null;
    }
  }

  /// Update an existing product
  Future<int> updateProduct(Product product) async {
    try {
      final db = await database;
      final rowsAffected = await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
      debugPrint('Product updated, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  /// Delete a product
  Future<int> deleteProduct(int id) async {
    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Product deleted, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      debugPrint('Error deleting product with ID $id: $e');
      rethrow;
    }
  }

  /// Toggle product favorite status
  Future<int> toggleProductFavorite(int productId) async {
    try {
      final product = await getProduct(productId);
      if (product != null) {
        final updatedProduct = product.copyWith(
          isFavorite: !product.isFavorite,
        );
        return await updateProduct(updatedProduct);
      }
      return 0;
    } catch (e) {
      debugPrint('Error toggling favorite for product $productId: $e');
      rethrow;
    }
  }

  /// Get favorite products
  Future<List<Product>> getFavoriteProducts() async {
    try {
      final db = await database;
      final result = await db.query(
        'products',
        where: 'isFavorite = ?',
        whereArgs: [1],
        orderBy: 'name ASC',
      );
      return result.map((json) => Product.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Error getting favorite products: $e');
      rethrow;
    }
  }

  // ==================== SHOPPING LIST METHODS ====================

  /// Insert a new shopping list
  Future<int> insertShoppingList(ShoppingList shoppingList) async {
    try {
      final db = await database;
      final map = shoppingList.toMap();
      final id = await db.insert('shopping_lists', map);
      debugPrint('Shopping list inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting shopping list: $e');
      rethrow;
    }
  }

  /// Get all shopping lists with their items
  Future<List<ShoppingList>> getAllShoppingLists() async {
    try {
      final db = await database;
      final result = await db.query(
        'shopping_lists',
        orderBy: 'createdAt DESC',
      );

      List<ShoppingList> lists = [];
      for (var listMap in result) {
        final shoppingList = ShoppingList.fromMap(listMap);
        // Load items for each shopping list
        final items = await getShoppingListItems(shoppingList.id!);
        lists.add(shoppingList.copyWith(items: items));
      }

      return lists;
    } catch (e) {
      debugPrint('Error getting all shopping lists: $e');
      rethrow;
    }
  }

  /// Get a single shopping list by ID
  Future<ShoppingList?> getShoppingList(int id) async {
    try {
      final db = await database;
      final result = await db.query(
        'shopping_lists',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final shoppingList = ShoppingList.fromMap(result.first);
        final items = await getShoppingListItems(id);
        return shoppingList.copyWith(items: items);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting shopping list with ID $id: $e');
      return null;
    }
  }

  /// Update an existing shopping list
  Future<int> updateShoppingList(ShoppingList shoppingList) async {
    try {
      final db = await database;
      final rowsAffected = await db.update(
        'shopping_lists',
        shoppingList.toMap(),
        where: 'id = ?',
        whereArgs: [shoppingList.id],
      );
      debugPrint('Shopping list updated, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      debugPrint('Error updating shopping list: $e');
      rethrow;
    }
  }

  /// Delete a shopping list and all its items
  Future<int> deleteShoppingList(int id) async {
    try {
      final db = await database;

      return await db.transaction((txn) async {
        // Delete items first (although CASCADE should handle this)
        await txn.delete(
          'shopping_list_items',
          where: 'shopping_list_id = ?',
          whereArgs: [id],
        );

        // Then delete the shopping list
        final rowsAffected = await txn.delete(
          'shopping_lists',
          where: 'id = ?',
          whereArgs: [id],
        );

        debugPrint('Shopping list deleted, rows affected: $rowsAffected');
        return rowsAffected;
      });
    } catch (e) {
      debugPrint('Error deleting shopping list with ID $id: $e');
      rethrow;
    }
  }

  // ==================== SHOPPING LIST ITEM METHODS ====================

  /// Insert a new shopping list item
  Future<int> insertShoppingListItem(ShoppingListItem item) async {
    try {
      final db = await database;
      final map = item.toMap();
      debugPrint('Inserting item: $map');
      final id = await db.insert('shopping_list_items', map);
      debugPrint('Shopping list item inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting shopping list item: $e');
      debugPrint('Item data: ${item.toMap()}');
      rethrow;
    }
  }

  /// Get all items for a shopping list
  Future<List<ShoppingListItem>> getShoppingListItems(
    int shoppingListId,
  ) async {
    try {
      final db = await database;
      final result = await db.query(
        'shopping_list_items',
        where: 'shopping_list_id = ?',
        whereArgs: [shoppingListId],
        orderBy: 'id ASC',
      );
      return result.map((json) => ShoppingListItem.fromMap(json)).toList();
    } catch (e) {
      debugPrint(
        'Error getting shopping list items for list $shoppingListId: $e',
      );
      rethrow;
    }
  }

  /// Get shopping list items with their associated products
  Future<List<ShoppingListItem>> getShoppingListItemsWithProduct(
    int shoppingListId,
  ) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        '''
        SELECT 
          sli.*,
          p.name as product_name,
          p.description as product_description,
          p.price as product_price,
          p.category as product_category,
          p.photoPath as product_photoPath,
          p.isFavorite as product_isFavorite
        FROM shopping_list_items sli
        LEFT JOIN products p ON sli.product_id = p.id
        WHERE sli.shopping_list_id = ?
        ORDER BY sli.id ASC
      ''',
        [shoppingListId],
      );

      List<ShoppingListItem> items = [];
      for (var row in result) {
        final item = ShoppingListItem.fromMap(row);

        // Create product from joined data if it exists
        Product? product;
        if (row['product_name'] != null) {
          product = Product(
            id: row['product_id'] as int,
            name: row['product_name'] as String,
            description: row['product_description'] as String? ?? '',
            price: row['product_price'] as double?,
            category: row['product_category'] as String?,
            photoPath: row['product_photoPath'] as String?,
            isFavorite: (row['product_isFavorite'] as int?) == 1,
          );
        }

        items.add(item.copyWith(product: product));
      }

      return items;
    } catch (e) {
      debugPrint(
        'Error getting shopping list items with products for list $shoppingListId: $e',
      );
      rethrow;
    }
  }

  /// Update a shopping list item
  Future<int> updateShoppingListItem(ShoppingListItem item) async {
    try {
      final db = await database;
      final rowsAffected = await db.update(
        'shopping_list_items',
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );
      debugPrint('Shopping list item updated, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      debugPrint('Error updating shopping list item: $e');
      rethrow;
    }
  }

  /// Delete a shopping list item
  Future<int> deleteShoppingListItem(int id) async {
    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'shopping_list_items',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('Shopping list item deleted, rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      debugPrint('Error deleting shopping list item with ID $id: $e');
      rethrow;
    }
  }

  /// Clear all items from a shopping list
  Future<void> clearShoppingListItems(int shoppingListId) async {
    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'shopping_list_items',
        where: 'shopping_list_id = ?',
        whereArgs: [shoppingListId],
      );
      debugPrint(
        'Cleared $rowsAffected items from shopping list $shoppingListId',
      );
    } catch (e) {
      debugPrint(
        'Error clearing shopping list items for list $shoppingListId: $e',
      );
      rethrow;
    }
  }

  /// Update item checked status
  Future<int> updateItemCheckedStatus(int itemId, bool isChecked) async {
    try {
      final db = await database;
      final rowsAffected = await db.update(
        'shopping_list_items',
        {'isChecked': isChecked ? 1 : 0},
        where: 'id = ?',
        whereArgs: [itemId],
      );
      return rowsAffected;
    } catch (e) {
      debugPrint('Error updating item checked status: $e');
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get database statistics for debugging
  Future<Map<String, int>> getDatabaseStats() async {
    try {
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
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      return {'products': 0, 'shopping_lists': 0, 'shopping_list_items': 0};
    }
  }

  /// Close database connection
  Future<void> closeDatabase() async {
    try {
      final db = _database;
      if (db != null) {
        await db.close();
        _database = null;
        debugPrint('Database closed');
      }
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }

  /// Delete entire database (for testing/reset)
  Future<void> deleteDatabase() async {
    try {
      await closeDatabase();
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, _databaseName);
      await databaseFactory.deleteDatabase(path);
      debugPrint('Database deleted');
    } catch (e) {
      debugPrint('Error deleting database: $e');
      rethrow;
    }
  }

  /// Export database data (for debugging)
  Future<Map<String, dynamic>> exportDatabaseData() async {
    try {
      final db = await database;

      final products = await db.query('products');
      final shoppingLists = await db.query('shopping_lists');
      final shoppingListItems = await db.query('shopping_list_items');

      return {
        'products': products,
        'shopping_lists': shoppingLists,
        'shopping_list_items': shoppingListItems,
      };
    } catch (e) {
      debugPrint('Error exporting database data: $e');
      return {};
    }
  }
}
