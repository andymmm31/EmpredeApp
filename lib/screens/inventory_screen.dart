import 'dart:io';
import 'package:flutter/material.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/screens/product_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _productsFuture = DatabaseHelper.instance.getAllProducts();
    });
  }

  void _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
    if (result == true) {
      _refreshProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No hay productos en el inventario.\nPresiona + para agregar uno.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                bool isLowStock = product.stock <= product.stockAlerta;

                return Card(
                  color: isLowStock ? Colors.red.withOpacity(0.2) : null,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: product.imagen != null && product.imagen!.isNotEmpty
                          ? FileImage(File(product.imagen!))
                          : null,
                      child: product.imagen == null || product.imagen!.isEmpty
                          ? Icon(Icons.inventory_2_outlined, color: Colors.grey.shade700)
                          : null,
                    ),
                    title: Text(product.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('Precio: \$${product.precioVenta.toStringAsFixed(2)}  |  Stock: ${product.stock}'),
                        Text('Margen: ${product.margenPorcentaje.toStringAsFixed(1)}%',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _navigateAndRefresh(ProductFormScreen(product: product)),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(ProductFormScreen()),
        tooltip: 'Nuevo Producto',
        child: Icon(Icons.add),
      ),
    );
  }
}