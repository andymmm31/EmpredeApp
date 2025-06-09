// lib/screens/pos_screen.dart
import 'package:flutter/material.dart';

// Modelo para los productos
class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? image;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.image,
  });
}

// Modelo para items del carrito
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get total => product.price * quantity;
}

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  // Lista de productos (puedes conectar esto a tu base de datos)
  final List<Product> _products = [
    Product(id: '1', name: 'Café Americano', price: 2.50, category: 'Bebidas'),
    Product(id: '2', name: 'Cappuccino', price: 3.00, category: 'Bebidas'),
    Product(id: '3', name: 'Sandwich Mixto', price: 4.50, category: 'Comida'),
    Product(id: '4', name: 'Croissant', price: 2.00, category: 'Panadería'),
    Product(id: '5', name: 'Jugo Natural', price: 3.50, category: 'Bebidas'),
    Product(id: '6', name: 'Ensalada César', price: 6.00, category: 'Comida'),
  ];

  // Carrito de compras
  final List<CartItem> _cart = [];
  
  // Categorías para filtrar
  String _selectedCategory = 'Todos';
  final List<String> _categories = ['Todos', 'Bebidas', 'Comida', 'Panadería'];

  // Método de pago seleccionado
  String _paymentMethod = 'Efectivo';
  final List<String> _paymentMethods = ['Efectivo', 'Tarjeta', 'Transferencia'];

  // Agregar producto al carrito
  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
    
    // Mostrar mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Remover producto del carrito
  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  // Actualizar cantidad en el carrito
  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = newQuantity;
      }
    });
  }

  // Limpiar carrito
  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  // Calcular total del carrito
  double get _cartTotal {
    return _cart.fold(0.0, (sum, item) => sum + item.total);
  }

  // Obtener productos filtrados por categoría
  List<Product> get _filteredProducts {
    if (_selectedCategory == 'Todos') {
      return _products;
    }
    return _products.where((product) => product.category == _selectedCategory).toList();
  }

  // Procesar venta
  void _processSale() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Venta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: \$${_cartTotal.toStringAsFixed(2)}'),
              Text('Método de pago: $_paymentMethod'),
              const SizedBox(height: 10),
              const Text('¿Confirmar la venta?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeSale();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Completar venta
  void _completeSale() {
    // Aquí puedes agregar la lógica para guardar la venta en base de datos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Venta completada por \$${_cartTotal.toStringAsFixed(2)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    _clearCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Panel izquierdo - Productos
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Filtros de categoría
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('Categoría: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: FilterChip(
                                  label: Text(category),
                                  selected: _selectedCategory == category,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid de productos
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        elevation: 3,
                        child: InkWell(
                          onTap: () => _addToCart(product),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getCategoryIcon(product.category),
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Panel derecho - Carrito y Pago
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // Encabezado del carrito
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Carrito',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_cart.isNotEmpty)
                        IconButton(
                          onPressed: _clearCart,
                          icon: const Icon(Icons.clear_all, color: Colors.white),
                          tooltip: 'Limpiar carrito',
                        ),
                    ],
                  ),
                ),
                
                // Lista del carrito
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Carrito vacío', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final cartItem = _cart[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem.product.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text('\$${cartItem.product.price.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    ),
                                    // Controles de cantidad
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _updateQuantity(index, cartItem.quantity - 1),
                                          icon: const Icon(Icons.remove_circle_outline),
                                          iconSize: 20,
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          onPressed: () => _updateQuantity(index, cartItem.quantity + 1),
                                          icon: const Icon(Icons.add_circle_outline),
                                          iconSize: 20,
                                        ),
                                      ],
                                    ),
                                    // Botón eliminar
                                    IconButton(
                                      onPressed: () => _removeFromCart(index),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      iconSize: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Sección de pago
                if (_cart.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Método de pago
                        const Text(
                          'Método de Pago:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Total
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${_cartTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Botón de procesar venta
                        ElevatedButton(
                          onPressed: _processSale,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'PROCESAR VENTA',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Obtener icono según la categoría
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Bebidas':
        return Icons.local_drink;
      case 'Comida':
        return Icons.restaurant;
      case 'Panadería':
        return Icons.cake;
      default:
        return Icons.shopping_bag;
    }
  }
}