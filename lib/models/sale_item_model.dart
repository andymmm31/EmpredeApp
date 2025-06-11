class SaleItemFields {
  static final List<String> values = [
    id,
    saleId,
    productId,
    quantity,
    priceAtSale,
    subtotal
  ];

  static const String id = '_id'; // Usar _id por convención de sqflite
  static const String saleId = 'sale_id'; // FK a la tabla sales
  static const String productId = 'product_id'; // FK a la tabla products
  static const String quantity = 'quantity'; // Cantidad vendida
  static const String priceAtSale =
      'price_at_sale'; // Precio del producto al momento de la venta
  static const String subtotal = 'subtotal'; // quantity * priceAtSale
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final int quantity;
  final double priceAtSale;
  final double subtotal;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.priceAtSale,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      SaleItemFields.id: id,
      SaleItemFields.saleId: saleId,
      SaleItemFields.productId: productId,
      SaleItemFields.quantity: quantity,
      SaleItemFields.priceAtSale: priceAtSale,
      SaleItemFields.subtotal: subtotal,
    };
  }

  static SaleItem fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map[SaleItemFields.id] as int?,
      saleId: map[SaleItemFields.saleId] as int,
      productId: map[SaleItemFields.productId] as int,
      quantity: map[SaleItemFields.quantity] as int,
      priceAtSale: map[SaleItemFields.priceAtSale] as double,
      subtotal: map[SaleItemFields.subtotal] as double,
    );
  }
}
