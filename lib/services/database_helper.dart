import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/models/category_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('emprende_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textTypeNull = 'TEXT';
    const integerTypeNull = 'INTEGER';

    await db.execute('''
      CREATE TABLE categories (
        ${CategoryFields.id} $idType,
        ${CategoryFields.nombre} $textType,
        ${CategoryFields.fechaCreacion} $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        ${ProductFields.id} $idType,
        ${ProductFields.nombre} $textType,
        ${ProductFields.descripcion} $textTypeNull,
        ${ProductFields.categoriaId} $integerTypeNull,
        ${ProductFields.precioVenta} $doubleType,
        ${ProductFields.costoProduccion} $doubleType,
        ${ProductFields.stock} $integerType,
        ${ProductFields.stockAlerta} $integerType,
        ${ProductFields.imagen} $textTypeNull,
        ${ProductFields.fechaCreacion} $textType,
        FOREIGN KEY (${ProductFields.categoriaId}) REFERENCES categories (${CategoryFields.id}) ON DELETE SET NULL
      )
    ''');
  }

  // --- MÉTODOS PARA CATEGORÍAS ---
  Future<Category> createCategory(Category category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap());
    return Category(id: id, nombre: category.nombre, fechaCreacion: category.fechaCreacion);
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: '${CategoryFields.nombre} ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: '${CategoryFields.id} = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS PARA PRODUCTOS ---
  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert('products', product.toMap());
    return Product(
        id: id,
        nombre: product.nombre,
        descripcion: product.descripcion,
        categoriaId: product.categoriaId,
        precioVenta: product.precioVenta,
        costoProduccion: product.costoProduccion,
        stock: product.stock,
        stockAlerta: product.stockAlerta,
        imagen: product.imagen,
        fechaCreacion: product.fechaCreacion);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: '${ProductFields.nombre} ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update('products', product.toMap(), where: '${ProductFields.id} = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: '${ProductFields.id} = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}