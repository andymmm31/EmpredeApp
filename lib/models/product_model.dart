// lib/models/product_model.dart

class ProductFields {
  // CORRECCIÓN PRINCIPAL: El ID en la base de datos se llama '_id'.
  static const String id = '_id';
  
  static const String nombre = 'nombre';
  static const String descripcion = 'descripcion';
  
  // CORRECCIÓN: Tu tabla de DB se llama 'precio_compra', no 'costo_produccion'.
  // Usaremos 'precio_compra' para coincidir con tu `database_helper.dart`.
  static const String precioCompra = 'precio_compra'; 
  
  static const String precioVenta = 'precio_venta';
  static const String stock = 'stock';
  static const String stockAlerta = 'stock_alerta';
  static const String categoriaId = 'categoria_id';
  static const String imagen = 'imagen';
  static const String fechaCreacion = 'fecha_creacion';
}

class Product {
  final int? id;
  final String nombre;
  final String? descripcion;
  final int? categoriaId;
  final double precioVenta;
  
  // CORRECCIÓN: El nombre de la propiedad debe coincidir con la DB para claridad.
  final double precioCompra; 
  
  int stock;
  final int stockAlerta;
  final String? imagen;
  final DateTime fechaCreacion;

  Product({
    this.id,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    required this.precioVenta,
    required this.precioCompra, // Cambiado de costoProduccion
    required this.stock,
    required this.stockAlerta,
    this.imagen,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      ProductFields.id: id,
      ProductFields.nombre: nombre,
      ProductFields.descripcion: descripcion,
      ProductFields.categoriaId: categoriaId,
      ProductFields.precioVenta: precioVenta,
      ProductFields.precioCompra: precioCompra, // Cambiado de costoProduccion
      ProductFields.stock: stock,
      ProductFields.stockAlerta: stockAlerta,
      ProductFields.imagen: imagen,
      ProductFields.fechaCreacion: fechaCreacion.toIso8601String(),
    };
  }

  // ================================================================
  // MÉTODO fromMap COMPLETAMENTE CORREGIDO Y ROBUSTO
  // ================================================================
  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      // Lee la clave correcta '_id' del mapa de la base de datos.
      id: map[ProductFields.id] as int?,
      
      nombre: map[ProductFields.nombre] as String? ?? 'Sin nombre',
      descripcion: map[ProductFields.descripcion] as String?,
      categoriaId: map[ProductFields.categoriaId] as int?,
      
      // Usa los métodos auxiliares para parsear de forma segura.
      precioVenta: _parseDouble(map[ProductFields.precioVenta]),
      precioCompra: _parseDouble(map[ProductFields.precioCompra]), // Cambiado de costoProduccion
      
      stock: _parseInt(map[ProductFields.stock]),
      stockAlerta: _parseInt(map[ProductFields.stockAlerta]),
      
      imagen: map[ProductFields.imagen] as String?,
      fechaCreacion: _parseDateTime(map[ProductFields.fechaCreacion]),
    );
  }

  // Métodos auxiliares para parsear datos de forma segura desde el mapa.
  // Esto evita crashes si un valor viene como null o un tipo incorrecto.
  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // Getter para calcular el margen. Ahora usa 'precioCompra'.
  double get margenPorcentaje {
    if (precioVenta <= 0 || precioCompra <= 0) return 0.0;
    return ((precioVenta - precioCompra) / precioVenta) * 100;
  }
}