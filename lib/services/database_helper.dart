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
    return await openDatabase(
      path, 
      version: 2, // INCREMENTÉ LA VERSIÓN PARA FORZAR RECREACIÓN
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recrear las tablas si hay cambios
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _createDB(db, newVersion);
    }
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

    // Crear categorías por defecto después de crear las tablas
    await _createDefaultCategories(db);
  }

  Future _onOpen(Database db) async {
    // Verificar y crear categorías por defecto al abrir la base de datos
    await _ensureDefaultCategories(db);
  }

  // Crear categorías por defecto al crear la base de datos
  Future<void> _createDefaultCategories(Database db) async {
    try {
      final defaultCategories = [
        Category(nombre: 'Vinos'),
        Category(nombre: 'Chocolates'),
      ];

      for (var category in defaultCategories) {
        await db.insert('categories', category.toMap());
      }
      print('Categorías por defecto creadas exitosamente');
    } catch (e) {
      print('Error al crear categorías por defecto: $e');
    }
  }

  // Asegurar que las categorías por defecto existan
  Future<void> _ensureDefaultCategories(Database db) async {
    try {
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
      final categoryCount = count.first['count'] as int;
      
      if (categoryCount == 0) {
        await _createDefaultCategories(db);
      } else {
        // Verificar si existen las categorías específicas
        final vinosExists = await db.query(
          'categories',
          where: '${CategoryFields.nombre} = ?',
          whereArgs: ['Vinos'],
        );
        
        final chocolatesExists = await db.query(
          'categories',
          where: '${CategoryFields.nombre} = ?',
          whereArgs: ['Chocolates'],
        );

        if (vinosExists.isEmpty) {
          await db.insert('categories', Category(nombre: 'Vinos').toMap());
        }

        if (chocolatesExists.isEmpty) {
          await db.insert('categories', Category(nombre: 'Chocolates').toMap());
        }
      }
    } catch (e) {
      print('Error al asegurar categorías por defecto: $e');
    }
  }

  // --- MÉTODOS PARA CATEGORÍAS ---
  Future<Category> createCategory(Category category) async {
    try {
      final db = await instance.database;
      final id = await db.insert('categories', category.toMap());
      return Category(id: id, nombre: category.nombre, fechaCreacion: category.fechaCreacion);
    } catch (e) {
      print('Error al crear categoría: $e');
      rethrow;
    }
  }

  Future<List<Category>> getAllCategories() async {
    try {
      final db = await instance.database;
      final result = await db.query('categories', orderBy: '${CategoryFields.nombre} ASC');
      print('Categorías obtenidas: ${result.length}');
      return result.map((json) => Category.fromMap(json)).toList();
    } catch (e) {
      print('Error al obtener categorías: $e');
      rethrow;
    }
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: '${CategoryFields.id} = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    return null;
  }

  Future<Category?> getCategoryByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: '${CategoryFields.nombre} = ?',
      whereArgs: [name],
    );
    
    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: '${CategoryFields.id} = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    
    // Verificar si hay productos asociados
    final productsWithCategory = await db.query(
      'products',
      where: '${ProductFields.categoriaId} = ?',
      whereArgs: [id],
    );

    if (productsWithCategory.isNotEmpty) {
      // Si hay productos, solo actualizar a null en lugar de eliminar
      await db.update(
        'products',
        {ProductFields.categoriaId: null},
        where: '${ProductFields.categoriaId} = ?',
        whereArgs: [id],
      );
    }

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

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: '${ProductFields.categoriaId} = ?',
      whereArgs: [categoryId],
      orderBy: '${ProductFields.nombre} ASC',
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT * FROM products 
      WHERE ${ProductFields.stock} <= ${ProductFields.stockAlerta}
      ORDER BY ${ProductFields.stock} ASC
    ''');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: '${ProductFields.nombre} LIKE ? OR ${ProductFields.descripcion} LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: '${ProductFields.nombre} ASC',
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: '${ProductFields.id} = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update('products', product.toMap(), where: '${ProductFields.id} = ?', whereArgs: [product.id]);
  }

  Future<int> updateProductStock(int productId, int newStock) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {ProductFields.stock: newStock},
      where: '${ProductFields.id} = ?',
      whereArgs: [productId],
    );
  }

  Future<int> adjustStock(int productId, int adjustment) async {
    final db = await instance.database;
    final product = await getProductById(productId);
    if (product != null) {
      final newStock = product.stock + adjustment;
      return await updateProductStock(productId, newStock.clamp(0, double.infinity).toInt());
    }
    return 0;
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: '${ProductFields.id} = ?', whereArgs: [id]);
  }

  // --- MÉTODOS DE ESTADÍSTICAS ---
  Future<Map<String, dynamic>> getInventoryStats() async {
    final db = await instance.database;
    
    final totalProducts = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final lowStockCount = await db.rawQuery('''
      SELECT COUNT(*) as count FROM products 
      WHERE ${ProductFields.stock} <= ${ProductFields.stockAlerta}
    ''');
    final totalValue = await db.rawQuery('''
      SELECT SUM(${ProductFields.precioVenta} * ${ProductFields.stock}) as total FROM products
    ''');
    final categoriesCount = await db.rawQuery('SELECT COUNT(*) as count FROM categories');

    return {
      'totalProducts': totalProducts.first['count'] as int,
      'lowStockProducts': lowStockCount.first['count'] as int,
      'totalInventoryValue': (totalValue.first['total'] as double?) ?? 0.0,
      'totalCategories': categoriesCount.first['count'] as int,
    };
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}