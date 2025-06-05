import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:emprende_app/models/product_model.dart'; // Asume que tienes este modelo
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/models/sale_model.dart';


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
    // Definición de tablas (similar a tu init_database)
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        categoria_id INTEGER,
        precio_venta REAL NOT NULL,
        costo_produccion REAL NOT NULL,
        stock INTEGER NOT NULL,
        stock_alerta INTEGER NOT NULL,
        imagen TEXT,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
      )
    ''');
     await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        total REAL NOT NULL,
        metodo_pago TEXT, 
        cliente TEXT,
        tipo TEXT DEFAULT 'Venta', 
        estado_entrega TEXT DEFAULT 'Pendiente' 
      )
    ''');
    await db.execute('''
      CREATE TABLE detalle_ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        venta_id INTEGER,
        producto_id INTEGER,
        cantidad INTEGER,
        precio_unitario REAL,
        FOREIGN KEY (venta_id) REFERENCES ventas (id),
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');

    // Insertar categorías por defecto
    final defaultCategories = ['Electrónicos', 'Ropa', 'Alimentos', 'Hogar', 'Deportes'];
    for (String category in defaultCategories) {
      // Usar ON CONFLICT IGNORE es más seguro que INSERT OR IGNORE en algunas versiones de SQLite/sqflite
      await db.rawInsert('INSERT OR IGNORE INTO categorias (nombre) VALUES (?)', [category]);
    }
  }

  // --- Métodos para Productos ---
  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('productos', product.toMap());
  }

  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'productos',
      columns: ProductFields.values, // Asume que tienes ProductFields en tu modelo
      where: '${ProductFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }
  
  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('productos', orderBy: '${ProductFields.nombre} ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      'productos',
      product.toMap(),
      where: '${ProductFields.id} = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'productos',
      where: '${ProductFields.id} = ?',
      whereArgs: [id],
    );
  }

  // --- Métodos para Categorías ---
  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categorias', orderBy: 'nombre ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> createCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categorias', category.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // --- Métodos para Ventas (Sales) ---
  Future<Sale> createSale(Sale sale, List<SaleDetail> details) async {
    final db = await instance.database;
    // Usa una transacción para asegurar la atomicidad
    await db.transaction((txn) async {
      final saleId = await txn.insert('ventas', sale.toMapWithoutId()); // Asume que el modelo lo maneja
      
      for (var detail in details) {
        detail.ventaId = saleId; // Asigna el ID de la venta al detalle
        await txn.insert('detalle_ventas', detail.toMap());
        
        // Actualizar stock si es una venta
        if (sale.tipo == 'Venta') {
          await txn.rawUpdate(
            'UPDATE productos SET stock = stock - ? WHERE id = ?',
            [detail.cantidad, detail.productoId]
          );
        }
      }
      sale.id = saleId; // Actualiza el ID en el objeto Sale
    });
    return sale;
  }

  Future<List<Sale>> getSalesByDateRangeAndFilters({
      required DateTime startDate, 
      required DateTime endDate, 
      String? typeFilter, 
      String? statusFilter
    }) async {
    final db = await instance.database;
    String whereClause = 'fecha BETWEEN ? AND ?';
    List<dynamic> whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];

    if (typeFilter != null && typeFilter != 'Todos') {
      whereClause += ' AND tipo = ?';
      whereArgs.add(typeFilter);
    }
    if (statusFilter != null && statusFilter != 'Todos') {
      whereClause += ' AND estado_entrega = ?';
      whereArgs.add(statusFilter);
    }
    
    final result = await db.query('ventas', where: whereClause, whereArgs: whereArgs, orderBy: 'fecha DESC');
    return result.map((json) => Sale.fromMap(json)).toList();
  }

  Future<List<SaleDetail>> getSaleDetails(int saleId) async {
    final db = await instance.database;
    final result = await db.query('detalle_ventas', where: 'venta_id = ?', whereArgs: [saleId]);
    return result.map((json) => SaleDetail.fromMap(json)).toList();
  }

  Future<int> updateSaleStatus(int saleId, String newStatus) async {
    final db = await instance.database;
    return db.update('ventas', {'estado_entrega': newStatus}, where: 'id = ?', whereArgs: [saleId]);
  }

  Future<void> convertQuoteToSale(int quoteId, String paymentMethod) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // 1. Obtener detalles de la cotización
      final details = await txn.query('detalle_ventas', where: 'venta_id = ?', whereArgs: [quoteId]);

      // 2. Verificar y descontar stock (¡IMPORTANTE: AÑADIR MANEJO DE ERRORES SI NO HAY STOCK!)
      for (var detail in details) {
        final currentStockResult = await txn.query('productos', columns: ['stock'], where: 'id = ?', whereArgs: [detail['producto_id']]);
        final currentStock = currentStockResult.first['stock'] as int;
        final quantityNeeded = detail['cantidad'] as int;

        if (currentStock < quantityNeeded) {
          throw Exception('Stock insuficiente para el producto ID ${detail['producto_id']}');
        }
        await txn.rawUpdate(
          'UPDATE productos SET stock = stock - ? WHERE id = ?',
          [quantityNeeded, detail['producto_id']]
        );
      }

      // 3. Actualizar la cotización a venta
      await txn.update(
        'ventas',
        {'tipo': 'Venta', 'estado_entrega': 'Por Entregar', 'metodo_pago': paymentMethod},
        where: 'id = ?',
        whereArgs: [quoteId]
      );
    });
  }


  // --- Métricas del Dashboard (Ejemplos, adapta tus queries) ---
  Future<Map<String, dynamic>?> getTopProductVolume() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT p.nombre, SUM(dv.cantidad) as total_vendido
      FROM detalle_ventas dv
      JOIN productos p ON dv.producto_id = p.id
      JOIN ventas v ON dv.venta_id = v.id WHERE v.tipo = 'Venta' AND v.estado_entrega = 'Entregada'
      GROUP BY p.nombre
      ORDER BY total_vendido DESC LIMIT 1
    ''');
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null; // Para que se reinicialice la próxima vez
  }
}