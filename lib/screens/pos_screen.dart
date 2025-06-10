// lib/screens/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/models/product_model.dart' as AppProduct; // Usamos un alias para evitar conflictos
import 'package:emprende_app/models/category_model.dart' as AppCategory;
import 'package:emprende_app/services/database_helper.dart';

// Modelo para items del carrito
class CartItem {
  final AppProduct.Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.precioVenta * quantity;
}

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  bool _isLoading = true;
  List<AppProduct.Product> _allProducts = [];
  List<AppCategory.Category> _allCategories = [];
  final List<CartItem> _cart = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      final categories = await DatabaseHelper.instance.getAllCategories();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _allCategories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToCart(AppProduct.Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }
  
  void _clearCart() => setState(() => _cart.clear());
  
  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = newQuantity;
      }
    });
  }

  double get _cartTotal => _cart.fold(0.0, (sum, item) => sum + item.total);

  List<AppProduct.Product> get _filteredProducts {
    if (_selectedCategoryId == null) {
      return _allProducts;
    }
    return _allProducts.where((p) => p.categoriaId == _selectedCategoryId).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Punto de Venta')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Panel de productos
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildCategoryFilters(),
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? Center(child: Text('No hay productos en esta categoría.'))
                            : GridView.builder(
                                padding: const EdgeInsets.all(8.0),
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 8.0,
                                  mainAxisSpacing: 8.0,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => _addToCart(product),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 40, color: Theme.of(context).primaryColor),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              children: [
                                                Text(product.nombre, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                                                SizedBox(height: 4),
                                                Text('\$${product.precioVenta.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Panel del carrito
                _buildCartPanel(),
              ],
            ),
    );
  }

  Widget _buildCategoryFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: Text('Todos'),
              selected: _selectedCategoryId == null,
              onSelected: (selected) => setState(() => _selectedCategoryId = null),
            ),
            ..._allCategories.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilterChip(
                  label: Text(category.nombre),
                  selected: _selectedCategoryId == category.id,
                  onSelected: (selected) => setState(() => _selectedCategoryId = category.id),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Container(
      width: 320,
      color: Colors.grey[100],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Carrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                if (_cart.isNotEmpty)
                  IconButton(onPressed: _clearCart, icon: Icon(Icons.delete_sweep, color: Colors.white), tooltip: 'Limpiar carrito'),
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey), SizedBox(height: 16), Text('Carrito vacío', style: TextStyle(color: Colors.grey))]))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return ListTile(
                        title: Text(item.product.nombre),
                        subtitle: Text('\$${item.product.precioVenta.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.remove), onPressed: () => _updateQuantity(index, item.quantity - 1)),
                            Text('${item.quantity}'),
                            IconButton(icon: Icon(Icons.add), onPressed: () => _updateQuantity(index, item.quantity + 1)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('\$${_cartTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700])),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () { /* Lógica de procesar venta */ },
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                      child: Text('PROCESAR VENTA'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}