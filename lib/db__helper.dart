import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'products.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL
      )
    ''');
  }

  // Add
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final dbClient = await db;
    return await dbClient.insert('products', product);
  }

  // Delete
  Future<int> deleteProduct(int id) async {
    final dbClient = await db;
    return await dbClient.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Fetch all
  Future<List<Map<String, dynamic>>> getProducts() async {
    final dbClient = await db;
    return await dbClient.query('products');
  }
}
