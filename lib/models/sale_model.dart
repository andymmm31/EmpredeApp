// Definición de campos para la base de datos
class SaleFields {
  static final List<String> values = [
    id,
    fecha,
    total,
    metodoPago,
    cliente,
    tipo,
    estadoEntrega,
    montoPagado,
    saldoPendiente,
  ];

  static const String id = '_id';
  static const String fecha = 'fecha';
  static const String total = 'total';
  static const String metodoPago = 'metodo_pago';
  static const String cliente = 'cliente';
  static const String tipo = 'tipo';
  static const String estadoEntrega = 'estado_entrega';
  static const String montoPagado = 'monto_pagado';
  static const String saldoPendiente = 'saldo_pendiente';
}

// Modelo para Ventas
class Sale {
  int? id;
  final DateTime fecha;
  final double total;
  final String? metodoPago;
  final String? cliente;
  String tipo; // 'Venta' o 'Cotizacion'
  String estadoEntrega; // 'Pendiente', 'Por Entregar', 'Entregada', 'Cancelada'
  double montoPagado; // Nuevo campo para monto pagado
  double saldoPendiente; // Nuevo campo para saldo pendiente

  Sale({
    this.id,
    DateTime? fecha,
    required this.total,
    this.metodoPago,
    this.cliente,
    this.tipo = 'Venta',
    this.estadoEntrega = 'Pendiente',
    double? montoPagado,
    double? saldoPendiente,
  })  : fecha = fecha ?? DateTime.now(),
        montoPagado = montoPagado ?? 0.0,
        saldoPendiente = saldoPendiente ?? total - (montoPagado ?? 0.0);

  // Getter para verificar si está completamente pagado
  bool get estaPagadoCompleto => saldoPendiente <= 0;

  // Getter para obtener el porcentaje pagado
  double get porcentajePagado => total > 0 ? (montoPagado / total) * 100 : 0;

  Map<String, dynamic> toMap() => {
        SaleFields.id: id,
        SaleFields.fecha: fecha.toIso8601String(),
        SaleFields.total: total,
        SaleFields.metodoPago: metodoPago,
        SaleFields.cliente: cliente,
        SaleFields.tipo: tipo,
        SaleFields.estadoEntrega: estadoEntrega,
        SaleFields.montoPagado: montoPagado,
        SaleFields.saldoPendiente: saldoPendiente,
      };

  // Para inserción, donde el ID es autoincremental
  Map<String, dynamic> toMapWithoutId() => {
        SaleFields.fecha: fecha.toIso8601String(),
        SaleFields.total: total,
        SaleFields.metodoPago: metodoPago,
        SaleFields.cliente: cliente,
        SaleFields.tipo: tipo,
        SaleFields.estadoEntrega: estadoEntrega,
        SaleFields.montoPagado: montoPagado,
        SaleFields.saldoPendiente: saldoPendiente,
      };

  static Sale fromMap(Map<String, dynamic> map) => Sale(
        id: map[SaleFields.id] as int?,
        fecha: DateTime.parse(map[SaleFields.fecha] as String),
        total: map[SaleFields.total] as double,
        metodoPago: map[SaleFields.metodoPago] as String?,
        cliente: map[SaleFields.cliente] as String?,
        tipo: map[SaleFields.tipo] as String? ?? 'Venta',
        estadoEntrega: map[SaleFields.estadoEntrega] as String? ?? 'Pendiente',
        montoPagado: (map[SaleFields.montoPagado] as num?)?.toDouble() ?? 0.0,
        saldoPendiente: (map[SaleFields.saldoPendiente] as num?)?.toDouble() ??
            ((map[SaleFields.total] as double) -
                ((map[SaleFields.montoPagado] as num?)?.toDouble() ?? 0.0)),
      );
}

// Modelo para Pagos (nuevo)
class Payment {
  final int? id;
  final int saleId;
  final double monto;
  final DateTime fecha;
  final String? metodoPago;
  final String? notas;

  Payment({
    this.id,
    required this.saleId,
    required this.monto,
    DateTime? fecha,
    this.metodoPago,
    this.notas,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'sale_id': saleId,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'metodo_pago': metodoPago,
        'notas': notas,
      };

  static Payment fromMap(Map<String, dynamic> map) => Payment(
        id: map['id'] as int?,
        saleId: map['sale_id'] as int,
        monto: map['monto'] as double,
        fecha: DateTime.parse(map['fecha'] as String),
        metodoPago: map['metodo_pago'] as String?,
        notas: map['notas'] as String?,
      );
}

// Modelo para Detalle de Ventas (mantener compatibilidad)
class SaleDetail {
  final int? id;
  int? ventaId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;

  SaleDetail({
    this.id,
    this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'venta_id': ventaId,
        'producto_id': productoId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      };

  static SaleDetail fromMap(Map<String, dynamic> map) => SaleDetail(
        id: map['id'] as int?,
        ventaId: map['venta_id'] as int?,
        productoId: map['producto_id'] as int,
        cantidad: map['cantidad'] as int,
        precioUnitario: map['precio_unitario'] as double,
      );
}
