// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/screens/inventory_screen.dart';
import 'package:emprende_app/screens/pos_screen.dart';
import 'package:emprende_app/screens/dashboard_screen.dart';
import 'package:emprende_app/screens/sales_management_screen.dart';

import 'package:emprende_app/models/product_model.dart' as app_product;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Inicia en la pestaña Dashboard

  // ESTADO DEL CARRITO CENTRALIZADO AQUÍ
  final List<CartItem> _cart = [];

  // ====================================================================
  // FUNCIÓN addToCart CORREGIDA Y MÁS SEGURA
  // ====================================================================
  void _addToCart(app_product.Product product) {
    // 1. **Validación Crítica**: Nos aseguramos de que el producto que llega
    //    desde la pantalla POS tenga un ID. Si no lo tiene, no hacemos nada
    //    y mostramos un mensaje de error en la consola para depuración.
    if (product.id == null) {
      print("ERROR FATAL: Se intentó añadir al carrito un producto sin ID: ${product.nombre}");
      // Opcional: Mostrar un SnackBar de error al usuario.
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error al añadir ${product.nombre}. Intente de nuevo.'), backgroundColor: Colors.red),
      // );
      return; // Detenemos la función aquí.
    }

    setState(() {
      // 2. Buscamos si el producto ya existe en el carrito usando su ID.
      final existingIndex =
          _cart.indexWhere((item) => item.product.id == product.id);

      if (existingIndex >= 0) {
        // 3. Si ya existe, simplemente incrementamos su cantidad.
        _cart[existingIndex].quantity++;
      } else {
        // 4. Si es un producto nuevo, lo añadimos al carrito.
        //    Como ya validamos que el producto tiene ID, esto es seguro.
        _cart.add(CartItem(product: product, quantity: 1));
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
    // Definimos las pantallas una sola vez para mejorar el rendimiento
    final List<Widget> widgetOptions = <Widget>[
      InventoryScreen(),
      POSScreen(
        cart: _cart,
        addToCart: _addToCart,
        clearCart: _clearCart,
        updateQuantity: _updateQuantity,
        cartTotal: _cartTotal,
      ),
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