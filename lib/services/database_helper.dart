import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/models/sale_model.dart'; // Importar el modelo de ventas

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
      version: 3, // Incrementamos la versión para incluir las tablas de ventas
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Si la versión anterior es menor a 2, recreamos categories y products
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _createDB(db, newVersion); // Recrea con la versión actual
    }
    // Si la versión anterior es menor a 3, creamos las tablas de ventas
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fecha TEXT NOT NULL,
          total REAL NOT NULL,
          metodo_pago TEXT,
          cliente TEXT,
          tipo TEXT NOT NULL,
          estado_entrega TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE sale_details (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          venta_id INTEGER NOT NULL,
          producto_id INTEGER NOT NULL,
          cantidad INTEGER NOT NULL,
          precio_unitario REAL NOT NULL,
          FOREIGN KEY (venta_id) REFERENCES sales (id) ON DELETE CASCADE,
          FOREIGN KEY (producto_id) REFERENCES products (id) ON DELETE RESTRICT
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const textTypeNull = 'TEXT';
    const integerTypeNull = 'INTEGER';

    // Tabla de Categorías
    await db.execute('''
      CREATE TABLE categories (
        ${CategoryFields.id} $idType,
        ${CategoryFields.nombre} $textType,
        ${CategoryFields.fechaCreacion} $textType
      )
    ''');

    // Tabla de Productos
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

    // Tablas de Ventas y Detalle de Ventas (NUEVAS)
    await db.execute('''
      CREATE TABLE sales (
        id $idType,
        fecha $textType,
        total $doubleType,
        metodo_pago $textTypeNull,
        cliente $textTypeNull,
        tipo $textType,
        estado_entrega $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_details (
        id $idType,
        venta_id $integerType,
        producto_id $integerType,
        cantidad $integerType,
        precio_unitario $doubleType,
        FOREIGN KEY (venta_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES products (id) ON DELETE RESTRICT
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

  // --- MÉTODOS PARA VENTAS ---

  Future<Sale> createSale(Sale sale) async {
    final db = await instance.database;
    final id = await db.insert('sales', sale.toMapWithoutId());
    return Sale(
      id: id,
      fecha: sale.fecha,
      total: sale.total,
      metodoPago: sale.metodoPago,
      cliente: sale.cliente,
      tipo: sale.tipo,
      estadoEntrega: sale.estadoEntrega,
    );
  }

  Future<SaleDetail> createSaleDetail(SaleDetail detail) async {
    final db = await instance.database;
    final id = await db.insert('sale_details', detail.toMap());
    return SaleDetail(
      id: id,
      ventaId: detail.ventaId,
      productoId: detail.productoId,
      cantidad: detail.cantidad,
      precioUnitario: detail.precioUnitario,
    );
  }

  Future<List<Sale>> getAllSales() async {
    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'fecha DESC');
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  Future<List<SaleDetail>> getSaleDetailsBySaleId(int saleId) async {
    final db = await instance.database;
    final result = await db.query(
      'sale_details',
      where: 'venta_id = ?',
      whereArgs: [saleId],
    );
    return result.map((json) => SaleDetail.fromMap(json)).toList();
  }

  /// **NUEVO MÉTODO:** Obtiene ventas filtradas por rango de fechas, tipo y estado.
  Future<List<Sale>> getSalesByDateRangeAndFilters({
    required DateTime startDate,
    required DateTime endDate,
    String? typeFilter, // 'Venta', 'Cotizacion' o null para todos
    String? statusFilter, // 'Pendiente', 'Por Entregar', 'Entregada', 'Cancelada' o null para todos
  }) async {
    final db = await instance.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    // Filtro por rango de fechas
    // Aseguramos que la fecha de inicio sea el comienzo del día y la de fin el final del día
    final String startIso = DateTime(startDate.year, startDate.month, startDate.day)
        .toIso8601String();
    final String endIso = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999)
        .toIso8601String();

    whereClauses.add('fecha BETWEEN ? AND ?');
    whereArgs.add(startIso);
    whereArgs.add(endIso);

    // Filtro por tipo de venta
    if (typeFilter != null && typeFilter.isNotEmpty) {
      whereClauses.add('tipo = ?');
      whereArgs.add(typeFilter);
    }

    // Filtro por estado de entrega
    if (statusFilter != null && statusFilter.isNotEmpty) {
      whereClauses.add('estado_entrega = ?');
      whereArgs.add(statusFilter);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      'sales',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC', // Ordenar por fecha, las más recientes primero
    );

    return result.map((json) => Sale.fromMap(json)).toList();
  }


  /// Procesa una venta completa de forma transaccional.
  /// Inserta la venta, los detalles de la venta y actualiza el stock de los productos.
  /// Retorna el ID de la venta creada o null si la transacción falla.
  Future<int?> processSale(Sale sale, List<SaleDetail> saleDetails) async {
    final db = await instance.database;
    int? saleId;

    await db.transaction((txn) async {
      try {
        // 1. Insertar la venta principal
        final newSaleId = await txn.insert('sales', sale.toMapWithoutId());
        saleId = newSaleId;

        // 2. Insertar los detalles de la venta y actualizar el stock de los productos
        for (var detail in saleDetails) {
          // Asignar el ID de la venta padre al detalle
          detail.ventaId = newSaleId;
          await txn.insert('sale_details', detail.toMap());

          // Obtener el producto actual para verificar stock
          final productMap = await txn.query(
            'products',
            where: '${ProductFields.id} = ?',
            whereArgs: [detail.productoId],
          );

          if (productMap.isEmpty) {
            throw Exception('Producto con ID ${detail.productoId} no encontrado.');
          }

          final currentProduct = Product.fromMap(productMap.first);

          if (currentProduct.stock < detail.cantidad) {
            throw Exception('Stock insuficiente para el producto ${currentProduct.nombre}. Stock disponible: ${currentProduct.stock}, requerido: ${detail.cantidad}');
          }

          // Actualizar el stock del producto
          final newStock = currentProduct.stock - detail.cantidad;
          await txn.update(
            'products',
            {ProductFields.stock: newStock},
            where: '${ProductFields.id} = ?',
            whereArgs: [detail.productoId],
          );
        }
        print('Venta procesada exitosamente con ID: $saleId');
      } catch (e) {
        print('Error en la transacción de venta: $e');
        // Lanzar la excepción para que la transacción se revierta
        rethrow; 
      }
    });
    return saleId;
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