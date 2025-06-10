// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/screens/inventory_screen.dart';
import 'package:emprende_app/screens/pos_screen.dart';
// Las siguientes líneas se pueden eliminar si las pantallas no se usan directamente aquí
// o si solo se usan como placeholders de texto.
// import 'package:emprende_app/screens/dashboard_screen.dart';
// import 'package:emprende_app/screens/sales_management_screen.dart';

// Cambiar el prefijo a lower_case_with_underscores para 'product_model'
import 'package:emprende_app/models/product_model.dart' as app_product; //
// import 'package:emprende_app/models/category_model.dart' as app_category; // Eliminar si no es usado.

// Asegúrate de que CartItem sea accesible. Como se define en pos_screen.dart,
// y pos_screen.dart se importa, CartItem debería ser accesible.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Inicia en la pestaña POS
  
  // ESTADO DEL CARRITO CENTRALIZADO AQUÍ
  final List<CartItem> _cart = [];

  void _addToCart(app_product.Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
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
    // Renombrar a 'widgetOptions' para quitar el guion bajo inicial
    final List<Widget> widgetOptions = <Widget>[ 
      InventoryScreen(),
      // Eliminar 'const' aquí porque POSScreen no es un constructor const
      POSScreen(
        cart: _cart,
        addToCart: _addToCart,
        clearCart: _clearCart,
        updateQuantity: _updateQuantity,
        cartTotal: _cartTotal,
      ),
      // Usar Text widgets como placeholders si no tienes las pantallas implementadas
      // O usa tus clases de pantalla si las tienes definidas
      const Center(child: Text('Dashboard Content')), 
      const Center(child: Text('Sales Management Content')),
    ];

    return Scaffold(
      body: Center(
        child: widgetOptions.elementAt(_selectedIndex), // Usar el nuevo nombre
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

// Las clases de las pantallas (DashboardScreen, SalesManagementScreen)
// si las tienes en archivos separados y completas,
// puedes descomentar sus imports y usarlas en lugar de los Text widgets.
// Si no las tienes, estos placeholders son correctos.