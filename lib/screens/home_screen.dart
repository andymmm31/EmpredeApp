// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/screens/inventory_screen.dart';
import 'package:emprende_app/screens/pos_screen.dart';
import 'package:emprende_app/screens/dashboard_screen.dart';
import 'package:emprende_app/screens/sales_management_screen.dart';

// Cambiar el prefijo a lower_case_with_underscores para 'product_model'
import 'package:emprende_app/models/product_model.dart' as app_product;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Inicia en la pestaña Dashboard (cambiado de 1 a 2)

  // ESTADO DEL CARRITO CENTRALIZADO AQUÍ
  final List<CartItem> _cart = [];

  void _addToCart(app_product.Product product) {
    setState(() {
      final existingIndex =
          _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _clearCart() {
    setState(() => _cart.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carrito limpiado.')),
    );
  }

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
  // FIN DEL ESTADO DEL CARRITO

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      InventoryScreen(),
      POSScreen(
        cart: _cart,
        addToCart: _addToCart,
        clearCart: _clearCart,
        updateQuantity: _updateQuantity,
        cartTotal: _cartTotal,
      ),
      // Usar las pantallas reales que ya tienes implementadas
      const DashboardScreen(),
      const SalesManagementScreen(),
    ];

    return Scaffold(
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Ventas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
