// Modelo para Ventas
class Sale {
  int? id;
  final DateTime fecha;
  final double total;
  final String? metodoPago;
  final String? cliente;
  String tipo; // 'Venta' o 'Cotizacion'
  String estadoEntrega; // 'Pendiente', 'Por Entregar', 'Entregada', 'Cancelada'

  Sale({
    this.id,
    DateTime? fecha,
    required this.total,
    this.metodoPago,
    this.cliente,
    this.tipo = 'Venta',
    this.estadoEntrega = 'Pendiente',
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'total': total,
        'metodo_pago': metodoPago,
        'cliente': cliente,
        'tipo': tipo,
        'estado_entrega': estadoEntrega,
      };
  
  // Para inserción, donde el ID es autoincremental
  Map<String, dynamic> toMapWithoutId() => {
        'fecha': fecha.toIso8601String(),
        'total': total,
        'metodo_pago': metodoPago,
        'cliente': cliente,
        'tipo': tipo,
        'estado_entrega': estadoEntrega,
      };

  static Sale fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        total: map['total'] as double,
        metodoPago: map['metodo_pago'] as String?,
        cliente: map['cliente'] as String?,
        tipo: map['tipo'] as String? ?? 'Venta',
        estadoEntrega: map['estado_entrega'] as String? ?? 'Pendiente',
      );
}

// Modelo para Detalle de Ventas
class SaleDetail {
  final int? id;
  int? ventaId; // Se asignará después de crear la venta padre
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