// lib/screens/inventory_screen.dart

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
  late Future<Map<String, List<Product>>> _groupedProductsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _groupedProductsFuture = _getGroupedProducts();
    });
  }

  Future<Map<String, List<Product>>> _getGroupedProducts() async {
    final products = await DatabaseHelper.instance.getAllProducts();
    final categories = await DatabaseHelper.instance.getAllCategories();
    final Map<int, String> categoryMap = {for (var c in categories) c.id!: c.nombre};
    
    final Map<String, List<Product>> grouped = {};
    for (var product in products) {
      final categoryName = categoryMap[product.categoriaId] ?? 'Sin Categoría';
      (grouped[categoryName] ??= []).add(product);
    }
    return grouped;
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
      body: FutureBuilder<Map<String, List<Product>>>(
        future: _groupedProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Este es el widget que se mostrará si hay un error
            return Center(child: Text('Error al cargar inventario: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Este es el widget para cuando no hay productos
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('Tu inventario está vacío', style: TextStyle(fontSize: 22, color: Colors.grey[700])),
                  SizedBox(height: 10),
                  Text('Presiona el botón + para agregar tu primer producto', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Agregar Producto'),
                    onPressed: () => _navigateAndRefresh(ProductFormScreen()),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                  ),
                ],
              ),
            );
          }

          final groupedProducts = snapshot.data!;
          final categories = groupedProducts.keys.toList();

          return RefreshIndicator(
            onRefresh: _refreshProducts,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final categoryName = categories[index];
                final productsInCategory = groupedProducts[categoryName]!;
                return ExpansionTile(
                  title: Text(categoryName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  initiallyExpanded: true,
                  children: productsInCategory.map((product) {
                    bool isLowStock = product.stock <= product.stockAlerta;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: product.imagen != null && product.imagen!.isNotEmpty ? FileImage(File(product.imagen!)) : null,
                        child: product.imagen == null || product.imagen!.isEmpty ? Icon(Icons.sell) : null,
                      ),
                      title: Text(product.nombre),
                      subtitle: Text('Precio: \$${product.precioVenta.toStringAsFixed(2)} | Stock: ${product.stock}'),
                      trailing: isLowStock ? Icon(Icons.warning_amber, color: Colors.orange) : null,
                      onTap: () => _navigateAndRefresh(ProductFormScreen(product: product)),
                    );
  
                  }).toList(),
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