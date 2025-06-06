class ProductFields {
  static final List<String> values = [
    id, nombre, descripcion, categoriaId, precioVenta, costoProduccion, stock, stockAlerta, imagen, fechaCreacion
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
  final int? categoriaId; // Podrías cargar el objeto Category aquí después
  final double precioVenta;
  final double costoProduccion;
  int stock;
  final int stockAlerta;
  final String? imagen; // Ruta de la imagen
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
    DateTime? fechaCreacion, // Permitir nulo para usar default
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
      nombre: map[ProductFields.nombre] as String,
      descripcion: map[ProductFields.descripcion] as String?,
      categoriaId: map[ProductFields.categoriaId] as int?,
      precioVenta: map[ProductFields.precioVenta] as double,
      costoProduccion: map[ProductFields.costoProduccion] as double,
      stock: map[ProductFields.stock] as int,
      stockAlerta: map[ProductFields.stockAlerta] as int,
      imagen: map[ProductFields.imagen] as String?,
      fechaCreacion: DateTime.parse(map[ProductFields.fechaCreacion] as String),
    );
  }

  double get margenPorcentaje {
    if (precioVenta <= 0) return 0.0;
    return ((precioVenta - costoProduccion) / precioVenta) * 100;
  }
}