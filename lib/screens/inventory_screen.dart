import 'package:flutter/material.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/screens/product_form_screen.dart'; // Para agregar/editar

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

  void _navigateToAddProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ProductFormScreen()), // Sin producto para agregar nuevo
    );
    if (result == true) { // Si el formulario indicó que se guardó algo
      _refreshProducts();
    }
  }

  void _navigateToEditProduct(Product product) async {
     final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ProductFormScreen(product: product)),
    );
    if (result == true) {
      _refreshProducts();
    }
  }
  
  Future<void> _deleteProduct(int id) async {
    // Mostrar diálogo de confirmación
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Eliminación'),
          content: Text('¿Está seguro de eliminar este producto?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await DatabaseHelper.instance.deleteProduct(id);
        _refreshProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto eliminado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar producto: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay productos en el inventario.'));
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
                  color: isLowStock ? Colors.red[100] : null,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    // leading: product.imagen != null ? Image.file(File(product.imagen!)) : Icon(Icons.inventory), // Necesitas manejar File
                    leading: Icon(Icons.inventory, color: isLowStock ? Colors.red : Theme.of(context).primaryColor),
                    title: Text(product.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Precio: \$${product.precioVenta.toStringAsFixed(2)} - Stock: ${product.stock}'),
                        Text('Costo: \$${product.costoProduccion.toStringAsFixed(2)} - Alerta: ${product.stockAlerta}'),
                        Text('Margen: ${product.margenPorcentaje.toStringAsFixed(1)}%'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _navigateToEditProduct(product),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product.id!),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToEditProduct(product), // O a una vista de detalle
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        tooltip: 'Nuevo Producto',
        child: Icon(Icons.add),
      ),
    );
  }
}