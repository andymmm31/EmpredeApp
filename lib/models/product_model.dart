class ProductFields {
  static final List<String> values = [
    id, nombre, descripcion, categoriaId, precioVenta, costoProduccion,
    stock, stockAlerta, imagen, fechaCreacion
  ];

  static const String id = 'id';
  static const String nombre = 'nombre';
  static const String descripcion = 'descripcion';
  static const String categoriaId = 'categoria_id';
  static const String precioVenta = 'precio_venta';
  static const String costoProduccion = 'costo_produccion';
  static const String stock = 'stock';
  static const String stockAlerta = 'stock_alerta';
  static const String imagen = 'imagen';
  static const String fechaCreacion = 'fecha_creacion';
}

class Product {
  final int? id;
  final String nombre;
  final String? descripcion;
  final int? categoriaId;
  final double precioVenta;
  final double costoProduccion;
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
    required this.costoProduccion,
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
      ProductFields.costoProduccion: costoProduccion,
      ProductFields.stock: stock,
      ProductFields.stockAlerta: stockAlerta,
      ProductFields.imagen: imagen,
      ProductFields.fechaCreacion: fechaCreacion.toIso8601String(),
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map[ProductFields.id] as int?,
      nombre: map[ProductFields.nombre] as String? ?? '',
      descripcion: map[ProductFields.descripcion] as String?,
      categoriaId: map[ProductFields.categoriaId] as int?,
      // Manejo seguro de valores double que pueden ser null
      precioVenta: _parseDouble(map[ProductFields.precioVenta]),
      costoProduccion: _parseDouble(map[ProductFields.costoProduccion]),
      // Manejo seguro de valores int que pueden ser null
      stock: _parseInt(map[ProductFields.stock]),
      stockAlerta: _parseInt(map[ProductFields.stockAlerta]),
      imagen: map[ProductFields.imagen] as String?,
      fechaCreacion: _parseDateTime(map[ProductFields.fechaCreacion]),
    );
  }

  // Método auxiliar para parsear double de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Método auxiliar para parsear int de forma segura
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Método auxiliar para parsear DateTime de forma segura
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  double get margenPorcentaje {
    if (precioVenta <= 0) return 0.0;
    return ((precioVenta - costoProduccion) / precioVenta) * 100;
  }
}