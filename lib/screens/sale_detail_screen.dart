// lib/screens/sale_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/models/sale_model.dart';
import 'package:emprende_app/models/sale_item_model.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class SaleDetailScreen extends StatefulWidget {
  final int saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late Future<Sale?> _saleFuture;
  late Future<List<SaleItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadSaleDetails();
  }

  void _loadSaleDetails() {
    setState(() {
      _saleFuture = DatabaseHelper.instance.getSaleById(widget.saleId); // Need to add getSaleById to DatabaseHelper
      _itemsFuture = DatabaseHelper.instance.getSaleItemsBySaleId(widget.saleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Venta'),
      ),
      body: FutureBuilder<Sale?>(
        future: _saleFuture,
        builder: (context, saleSnapshot) {
          if (saleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (saleSnapshot.hasError) {
            return Center(child: Text('Error al cargar venta: ${saleSnapshot.error}'));
          } else if (!saleSnapshot.hasData || saleSnapshot.data == null) {
            return const Center(child: Text('Venta no encontrada.'));
          }

          final sale = saleSnapshot.data!;

          return FutureBuilder<List<SaleItem>>(
            future: _itemsFuture,
            builder: (context, itemsSnapshot) {
              if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (itemsSnapshot.hasError) {
                return Center(child: Text('Error al cargar items: ${itemsSnapshot.error}'));
              }

              final items = itemsSnapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo: ${sale.tipo}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Fecha: ${DateFormat.yMd().add_jm().format(sale.fecha)}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Cliente: ${sale.cliente ?? "N/A"}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Estado: ${sale.estadoEntrega}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    if (items.isEmpty)
                      const Text('No hay items para esta venta.')
                    else
                      ListView.builder(
                        shrinkWrap: true, // Important for ListView inside SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this list
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          // You would typically fetch product details here using item.productId
                          // For now, just display item details
                          return ListTile(
                            title: Text('Producto ID: ${item.productId}'), // Replace with product name
                            subtitle: Text('Cantidad: ${item.quantity} x \$${item.priceAtSale.toStringAsFixed(2)}'),
                            trailing: Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('\$${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    // Add more details or actions here (e.g., print receipt, edit status)
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// NOTE: You need to add a getSaleById method to your DatabaseHelper class.
// Example:
// Future<Sale?> getSaleById(int id) async {
//   final db = await instance.database;
//   final result = await db.query(
//     'sales',
//     where: '${SaleFields.id} = ?',
//     whereArgs: [id],
//   );
//   if (result.isNotEmpty) {
//     return Sale.fromMap(result.first);
//   }
//   return null;
// }
