class SaleFields {
  static final List<String> values = [
    id, tipo, cliente, total, estadoEntrega, fecha
  ];

  static const String id = '_id'; // Usar _id por convención de sqflite
  static const String tipo = 'tipo'; // 'Venta' o 'Cotizacion'
  static const String cliente = 'cliente'; // Nombre del cliente (opcional)
  static const String total = 'total'; // Total de la venta/cotizacion
  static const String estadoEntrega = 'estado_entrega'; // 'Pendiente', 'Por Entregar', 'Entregada', 'Cancelada'
  static const String fecha = 'fecha'; // Fecha y hora de la transacción
}

class Sale {
  final int? id;
  final String tipo;
  final String? cliente;
  final double total;
  final String estadoEntrega;
  final DateTime fecha;

  Sale({
    this.id,
    required this.tipo,
    this.cliente,
    required this.total,
    required this.estadoEntrega,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      SaleFields.id: id,
      SaleFields.tipo: tipo,
      SaleFields.cliente: cliente,
      SaleFields.total: total,
      SaleFields.estadoEntrega: estadoEntrega,
      SaleFields.fecha: fecha.toIso8601String(),
    };
  }

  static Sale fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map[SaleFields.id] as int?,
      tipo: map[SaleFields.tipo] as String,
      cliente: map[SaleFields.cliente] as String?,
      total: map[SaleFields.total] as double,
      estadoEntrega: map[SaleFields.estadoEntrega] as String,
      fecha: DateTime.parse(map[SaleFields.fecha] as String),
    );
  }
}
