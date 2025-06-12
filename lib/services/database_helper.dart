// lib/services/database_helper.dart

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/models/sale_model.dart';
import 'package:emprende_app/models/sale_item_model.dart';

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
      version: 2, // Incrementar versión para incluir nuevos campos
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Crear tabla de categorías
    await db.execute('''
      CREATE TABLE categories (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        color TEXT
      )
    ''');

    // Crear tabla de productos
    await db.execute('''
      CREATE TABLE products (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio_compra REAL NOT NULL DEFAULT 0,
        precio_venta REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        stock_alerta INTEGER NOT NULL DEFAULT 5,
        categoria_id INTEGER,
        imagen TEXT,
        fecha_creacion TEXT NOT NULL,
        FOREIGN KEY (categoria_id) REFERENCES categories (_id) ON DELETE SET NULL
      )
    ''');

    // Crear tabla de ventas con todos los campos necesarios
    await db.execute('''
      CREATE TABLE sales (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        metodo_pago TEXT,
        cliente TEXT,
        tipo TEXT NOT NULL DEFAULT 'Venta',
        estado_entrega TEXT NOT NULL DEFAULT 'Pendiente',
        monto_pagado REAL NOT NULL DEFAULT 0,
        saldo_pendiente REAL NOT NULL DEFAULT 0
      )
    ''');

    // Crear tabla de items de venta
    await db.execute('''
      CREATE TABLE sale_items (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price_at_sale REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (_id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (_id) ON DELETE CASCADE
      )
    ''');

    // Crear tabla de pagos (opcional para manejo de pagos parciales)
    await db.execute('''
      CREATE TABLE payments (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        metodo_pago TEXT,
        notas TEXT,
        FOREIGN KEY (sale_id) REFERENCES sales (_id) ON DELETE CASCADE
      )
    ''');

    // Insertar datos de ejemplo
    await _insertSampleData(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar campos faltantes a la tabla sales si no existen
      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN monto_pagado REAL NOT NULL DEFAULT 0');
      } catch (e) {
        print('Campo monto_pagado ya existe o error: $e');
      }

      try {
        await db.execute(
            'ALTER TABLE sales ADD COLUMN saldo_pendiente REAL NOT NULL DEFAULT 0');
      } catch (e) {
        print('Campo saldo_pendiente ya existe o error: $e');
      }
    }
  }

  Future<void> _insertSampleData(DatabaseExecutor db) async {
    // Insertar categorías de ejemplo
    await db.insert('categories', {
      'nombre': 'Chocolates',
      'descripcion': 'Dulces y chocolates',
      'color': '#8B4513'
    });

    await db.insert('categories', {
      'nombre': 'Tecnología',
      'descripcion': 'Productos tecnológicos',
      'color': '#4169E1'
    });

    await db.insert('categories', {
      'nombre': 'Vinos',
      'descripcion': 'Bebidas alcohólicas',
      'color': '#722F37'
    });

    // Insertar productos de ejemplo
    await db.insert('products', {
      'nombre': 'Laptop',
      'descripcion': 'Intel 5 7ma',
      'precio_compra': 800.0,
      'precio_venta': 1000.0,
      'stock': 5,
      'stock_alerta': 2,
      'categoria_id': 2,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });

    await db.insert('products', {
      'nombre': 'Chocolate Premium',
      'descripcion': 'Chocolate belga premium',
      'precio_compra': 5.0,
      'precio_venta': 8.0,
      'stock': 50,
      'stock_alerta': 10,
      'categoria_id': 1,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });

    await db.insert('products', {
      'nombre': 'Vino Tinto',
      'descripcion': 'Vino tinto reserva',
      'precio_compra': 15.0,
      'precio_venta': 25.0,
      'stock': 20,
      'stock_alerta': 5,
      'categoria_id': 3,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================================================
  // MÉTODOS PARA CATEGORÍAS
  // ==========================================================================

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'nombre ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> createCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: '_id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: '_id = ?', whereArgs: [id]);
  }

  // ==========================================================================
  // MÉTODOS PARA PRODUCTOS
  // ==========================================================================

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'nombre ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'categoria_id = ?',
      whereArgs: [categoryId],
      orderBy: 'nombre ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: '_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<int> createProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: '_id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: '_id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT * FROM products 
      WHERE stock <= stock_alerta
      ORDER BY stock ASC
    ''');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProductStock(int productId, int newStock) async {
    final db = await database;
    return await db.update(
      'products',
      {'stock': newStock},
      where: '_id = ?',
      whereArgs: [productId],
    );
  }

  // ==========================================================================
  // MÉTODOS PARA VENTAS
  // ==========================================================================

  Future<int> createSale(Sale sale, List<SaleItem> saleItems) async {
    final db = await database;

    return await db.transaction((txn) async {
      try {
        // 1. Insertar la venta usando toMapWithoutId() para evitar conflictos con el ID
        final saleId = await txn.insert(
          'sales',
          sale.toMapWithoutId(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 2. Insertar los items de la venta
        for (final item in saleItems) {
          final itemWithSaleId = SaleItem(
            saleId: saleId,
            productId: item.productId,
            quantity: item.quantity,
            priceAtSale: item.priceAtSale,
            subtotal: item.subtotal,
          );

          await txn.insert(
            'sale_items',
            itemWithSaleId.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // 3. Actualizar stock del producto
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE _id = ?',
            [item.quantity, item.productId],
          );
        }

        return saleId;
      } catch (e) {
        print('Error en createSale transaction: $e');
        rethrow;
      }
    });
  }

  Future<List<Sale>> getAllSales() async {
    final db = await database;
    final result = await db.query('sales', orderBy: 'fecha DESC');
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await database;
    final result = await db.query(
      'sales',
      where: '_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Sale.fromMap(result.first);
    }
    return null;
  }

  Future<List<Sale>> getSalesByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.query(
      'sales',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'fecha DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByDateRangeAndFilters({
    required DateTime startDate,
    required DateTime endDate,
    String? typeFilter,
    String? statusFilter,
  }) async {
    final db = await database;

    String whereClause = 'fecha BETWEEN ? AND ?';
    List<dynamic> whereArgs = [
      startDate.toIso8601String(),
      endDate.toIso8601String()
    ];

    if (typeFilter != null && typeFilter != 'Todos') {
      whereClause += ' AND tipo = ?';
      whereArgs.add(typeFilter);
    }

    if (statusFilter != null && statusFilter != 'Todos') {
      whereClause += ' AND estado_entrega = ?';
      whereArgs.add(statusFilter);
    }

    final result = await db.query(
      'sales',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC',
    );

    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<int> updateSale(Sale sale) async {
    final db = await database;
    return await db.update(
      'sales',
      sale.toMap(),
      where: '_id = ?',
      whereArgs: [sale.id],
    );
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    return await db.delete('sales', where: '_id = ?', whereArgs: [id]);
  }

  // ==========================================================================
  // MÉTODOS PARA ITEMS DE VENTA
  // ==========================================================================

  Future<List<SaleItem>> getSaleItemsBySaleId(int saleId) async {
    final db = await database;
    final result = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return result.map((map) => SaleItem.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getSaleItemsWithProductInfo(
      int saleId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        si.*,
        p.nombre as product_name,
        p.descripcion as product_description
      FROM sale_items si
      INNER JOIN products p ON si.product_id = p._id
      WHERE si.sale_id = ?
    ''', [saleId]);
    return result;
  }

  // ==========================================================================
  // MÉTODOS PARA ESTADÍSTICAS Y REPORTES
  // ==========================================================================

  Future<Map<String, dynamic>> getInventoryStats() async {
    final db = await database;

    // Total de productos
    final totalProducts =
        await db.rawQuery('SELECT COUNT(*) as count FROM products');

    // Total de categorías
    final totalCategories =
        await db.rawQuery('SELECT COUNT(*) as count FROM categories');

    // Productos con stock bajo
    final lowStockProducts = await db.rawQuery('''
      SELECT COUNT(*) as count FROM products WHERE stock <= stock_alerta
    ''');

    // Valor total del inventario
    final inventoryValue = await db.rawQuery('''
      SELECT SUM(stock * precio_venta) as total FROM products
    ''');

    // Estadísticas de ventas
    final salesStats = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sales,
        SUM(total) as total_sales_value,
        COUNT(CASE WHEN tipo = 'Venta' THEN 1 END) as sales_count,
        COUNT(CASE WHEN tipo = 'Cotizacion' THEN 1 END) as quotes_count,
        SUM(CASE WHEN tipo = 'Venta' THEN total ELSE 0 END) as sales_value,
        SUM(CASE WHEN tipo = 'Cotizacion' THEN total ELSE 0 END) as quotes_value,
        COUNT(CASE WHEN estado_entrega = 'Pendiente' THEN 1 END) as pending_sales,
        COUNT(CASE WHEN estado_entrega = 'Por Entregar' THEN 1 END) as to_deliver_sales
      FROM sales
    ''');

    return {
      'totalProducts': totalProducts.first['count'] ?? 0,
      'totalCategories': totalCategories.first['count'] ?? 0,
      'lowStockProducts': lowStockProducts.first['count'] ?? 0,
      'totalInventoryValue': inventoryValue.first['total'] ?? 0.0,
      'totalSales': salesStats.first['total_sales'] ?? 0,
      'totalSalesValue': salesStats.first['total_sales_value'] ?? 0.0,
      'salesCount': salesStats.first['sales_count'] ?? 0,
      'quotesCount': salesStats.first['quotes_count'] ?? 0,
      'salesValue': salesStats.first['sales_value'] ?? 0.0,
      'quotesValue': salesStats.first['quotes_value'] ?? 0.0,
      'pendingSalesCount': salesStats.first['pending_sales'] ?? 0,
      'toDeliverSalesCount': salesStats.first['to_deliver_sales'] ?? 0,
    };
  }

  Future<Map<String, dynamic>> getSalesSummaryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_transactions,
        COUNT(CASE WHEN tipo = 'Venta' THEN 1 END) as sales_count,
        COUNT(CASE WHEN tipo = 'Cotizacion' THEN 1 END) as quotes_count,
        SUM(CASE WHEN tipo = 'Venta' THEN total ELSE 0 END) as sales_total,
        SUM(CASE WHEN tipo = 'Cotizacion' THEN total ELSE 0 END) as quotes_total,
        AVG(CASE WHEN tipo = 'Venta' THEN total END) as avg_sale_amount,
        MAX(total) as max_transaction,
        MIN(total) as min_transaction
      FROM sales 
      WHERE fecha BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'totalTransactions': result.first['total_transactions'] ?? 0,
      'salesCount': result.first['sales_count'] ?? 0,
      'quotesCount': result.first['quotes_count'] ?? 0,
      'salesTotal': result.first['sales_total'] ?? 0.0,
      'quotesTotal': result.first['quotes_total'] ?? 0.0,
      'avgSaleAmount': result.first['avg_sale_amount'] ?? 0.0,
      'maxTransaction': result.first['max_transaction'] ?? 0.0,
      'minTransaction': result.first['min_transaction'] ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(
      {int limit = 10}) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT 
        p.nombre,
        p.precio_venta,
        SUM(si.quantity) as total_sold,
        SUM(si.subtotal) as total_revenue
      FROM sale_items si
      INNER JOIN products p ON si.product_id = p._id
      INNER JOIN sales s ON si.sale_id = s._id
      WHERE s.tipo = 'Venta'
      GROUP BY si.product_id, p.nombre, p.precio_venta
      ORDER BY total_sold DESC
      LIMIT ?
    ''', [limit]);

    return result;
  }

  Future<List<Map<String, dynamic>>> getSalesByMonth({int? year}) async {
    final db = await database;

    final currentYear = year ?? DateTime.now().year;

    final result = await db.rawQuery('''
      SELECT 
        CAST(strftime('%m', fecha) AS INTEGER) as month,
        COUNT(*) as sales_count,
        SUM(total) as total_amount
      FROM sales 
      WHERE strftime('%Y', fecha) = ? AND tipo = 'Venta'
      GROUP BY strftime('%m', fecha)
      ORDER BY month
    ''', [currentYear.toString()]);

    return result;
  }

  // ==========================================================================
  // MÉTODOS PARA PAGOS
  // ==========================================================================

  Future<int> createPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsBySaleId(int saleId) async {
    final db = await database;
    final result = await db.query(
      'payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'fecha DESC',
    );
    return result.map((map) => Payment.fromMap(map)).toList();
  }

  // ==========================================================================
  // MÉTODOS DE UTILIDAD
  // ==========================================================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('sale_items');
      await txn.delete('sales');
      await txn.delete('products');
      await txn.delete('categories');
    });
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('sale_items');
      await txn.delete('sales');
      await txn.delete('products');
      await txn.delete('categories');
      await _insertSampleData(txn);
    });
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;

    final tables = [
      'categories',
      'products',
      'sales',
      'sale_items',
      'payments'
    ];
    Map<String, dynamic> info = {};

    for (String table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      info[table] = result.first['count'];
    }

    return info;
  }

  // Agregar estos métodos al final de tu DatabaseHelper (antes del método close())

  // Método para buscar productos por nombre o descripción
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;

    if (query.isEmpty) {
      return await getAllProducts();
    }

    final result = await db.query(
      'products',
      where: 'nombre LIKE ? OR descripcion LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nombre ASC',
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Método para ajustar stock (sumar o restar)
  Future<int> adjustStock(int productId, int adjustment) async {
    final db = await database;

    // Primero obtener el stock actual
    final result = await db.query(
      'products',
      columns: ['stock'],
      where: '_id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('Producto no encontrado');
    }

    final currentStock = result.first['stock'] as int;
    final newStock = currentStock + adjustment;

    // Validar que el stock no sea negativo
    if (newStock < 0) {
      throw Exception('El stock no puede ser negativo');
    }

    // Actualizar el stock
    return await db.update(
      'products',
      {'stock': newStock},
      where: '_id = ?',
      whereArgs: [productId],
    );
  }

  // Método para obtener categoría por nombre
  Future<Category?> getCategoryByName(String name) async {
    final db = await database;

    final result = await db.query(
      'categories',
      where: 'nombre = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    return null;
  }

  // Método adicional para obtener categoría por ID
  Future<Category?> getCategoryById(int id) async {
    final db = await database;

    final result = await db.query(
      'categories',
      where: '_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    return null;
  }

  // ==========================================================================
  // MÉTODOS ADICIONALES PARA ANÁLISIS Y REPORTES
  // ==========================================================================

  // Obtener ventas diarias en un rango de fechas
  Future<List<Map<String, dynamic>>> getDailySales({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        DATE(fecha) as date,
        SUM(total) as daily_total,
        COUNT(*) as daily_count,
        COUNT(CASE WHEN tipo = 'Venta' THEN 1 END) as sales_count,
        COUNT(CASE WHEN tipo = 'Cotizacion' THEN 1 END) as quotes_count,
        SUM(CASE WHEN tipo = 'Venta' THEN total ELSE 0 END) as sales_total,
        SUM(CASE WHEN tipo = 'Cotizacion' THEN total ELSE 0 END) as quotes_total
      FROM sales 
      WHERE fecha BETWEEN ? AND ?
      GROUP BY DATE(fecha)
      ORDER BY DATE(fecha)
    ''', [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);
    
    return result;
  }

  // Obtener productos más vendidos en un período (versión actualizada)
  Future<List<Map<String, dynamic>>> getTopSellingProductsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        p.nombre as product_name,
        p._id as product_id,
        p.precio_venta as current_price,
        SUM(si.quantity) as total_quantity,
        SUM(si.subtotal) as total_revenue,
        COUNT(DISTINCT s._id) as sales_count,
        AVG(si.price_at_sale) as avg_sale_price
      FROM sales s
      INNER JOIN sale_items si ON s._id = si.sale_id
      INNER JOIN products p ON si.product_id = p._id
      WHERE s.fecha BETWEEN ? AND ?
        AND s.tipo = 'Venta'
      GROUP BY p._id, p.nombre, p.precio_venta
      ORDER BY total_quantity DESC
      LIMIT ?
    ''', [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
      limit,
    ]);
    
    return result;
  }

  // Obtener ventas por categoría en un período
  Future<List<Map<String, dynamic>>> getSalesByCategory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        c.nombre as category_name,
        c._id as category_id,
        c.color as category_color,
        SUM(si.quantity) as total_quantity,
        SUM(si.subtotal) as total_revenue,
        COUNT(DISTINCT s._id) as sales_count,
        COUNT(DISTINCT p._id) as products_sold
      FROM sales s
      INNER JOIN sale_items si ON s._id = si.sale_id
      INNER JOIN products p ON si.product_id = p._id
      INNER JOIN categories c ON p.categoria_id = c._id
      WHERE s.fecha BETWEEN ? AND ?
        AND s.tipo = 'Venta'
      GROUP BY c._id, c.nombre, c.color
      ORDER BY total_revenue DESC
    ''', [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);
    
    return result;
  }

  // Obtener estadísticas de ventas por método de pago
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(metodo_pago, 'Sin especificar') as payment_method,
        COUNT(*) as transaction_count,
        SUM(total) as total_amount,
        AVG(total) as avg_transaction
      FROM sales
      WHERE fecha BETWEEN ? AND ?
        AND tipo = 'Venta'
      GROUP BY metodo_pago
      ORDER BY total_amount DESC
    ''', [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);
    
    return result;
  }

  // Obtener ventas por estado de entrega
  Future<List<Map<String, dynamic>>> getSalesByDeliveryStatus({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        estado_entrega as delivery_status,
        COUNT(*) as count,
        SUM(total) as total_amount,
        SUM(monto_pagado) as total_paid,
        SUM(saldo_pendiente) as total_pending
      FROM sales
      WHERE fecha BETWEEN ? AND ?
        AND tipo = 'Venta'
      GROUP BY estado_entrega
      ORDER BY count DESC
    ''', [
      startDate.toIso8601String(),
      endDate.toIso8601String(),
    ]);
    
    return result;
  }

  // Obtener tendencia de ventas (comparación periodo actual vs anterior)
  Future<Map<String, dynamic>> getSalesTrend({
    required DateTime currentStartDate,
    required DateTime currentEndDate,
    required DateTime previousStartDate,
    required DateTime previousEndDate,
  }) async {
    final db = await database;
    
    // Ventas del período actual
    final currentResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as sales_count,
        SUM(total) as total_amount,
        AVG(total) as avg_amount
      FROM sales
      WHERE fecha BETWEEN ? AND ?
        AND tipo = 'Venta'
    ''', [
      currentStartDate.toIso8601String(),
      currentEndDate.toIso8601String(),
    ]);
    
    // Ventas del período anterior
    final previousResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as sales_count,
        SUM(total) as total_amount,
        AVG(total) as avg_amount
      FROM sales
      WHERE fecha BETWEEN ? AND ?
        AND tipo = 'Venta'
    ''', [
      previousStartDate.toIso8601String(),
      previousEndDate.toIso8601String(),
    ]);
    
    final current = currentResult.first;
    final previous = previousResult.first;
    
    // Calcular porcentajes de cambio
    double calculatePercentageChange(dynamic current, dynamic previous) {
      final currentVal = (current ?? 0).toDouble();
      final previousVal = (previous ?? 0).toDouble();
      
      if (previousVal == 0) return currentVal > 0 ? 100.0 : 0.0;
      return ((currentVal - previousVal) / previousVal) * 100;
    }
    
    return {
      'current': {
        'sales_count': current['sales_count'] ?? 0,
        'total_amount': current['total_amount'] ?? 0.0,
        'avg_amount': current['avg_amount'] ?? 0.0,
      },
      'previous': {
        'sales_count': previous['sales_count'] ?? 0,
        'total_amount': previous['total_amount'] ?? 0.0,
        'avg_amount': previous['avg_amount'] ?? 0.0,
      },
      'change': {
        'sales_count_change': calculatePercentageChange(
          current['sales_count'], 
          previous['sales_count']
        ),
        'total_amount_change': calculatePercentageChange(
          current['total_amount'], 
          previous['total_amount']
        ),
        'avg_amount_change': calculatePercentageChange(
          current['avg_amount'], 
          previous['avg_amount']
        ),
      }
    };
  }

  // Obtener resumen de inventario con alertas
  Future<Map<String, dynamic>> getInventoryAlerts() async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(CASE WHEN stock = 0 THEN 1 END) as out_of_stock,
        COUNT(CASE WHEN stock > 0 AND stock <= stock_alerta THEN 1 END) as low_stock,
        COUNT(CASE WHEN stock > stock_alerta THEN 1 END) as normal_stock,
        SUM(stock * precio_compra) as total_cost_value,
        SUM(stock * precio_venta) as total_sell_value
      FROM products
    ''');
    
    final inventoryData = result.first;
    
    // Obtener productos específicos con alertas
    final alertProducts = await db.rawQuery('''
      SELECT 
        _id,
        nombre,
        stock,
        stock_alerta,
        precio_venta,
        CASE 
          WHEN stock = 0 THEN 'Sin stock'
          WHEN stock <= stock_alerta THEN 'Stock bajo'
          ELSE 'Normal'
        END as alert_type
      FROM products
      WHERE stock <= stock_alerta
      ORDER BY stock ASC, nombre ASC
    ''');
    
    return {
      'summary': inventoryData,
      'alert_products': alertProducts,
    };
  }
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
