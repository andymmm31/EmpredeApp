// lib/screens/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/models/product_model.dart' as AppProduct;
import 'package:emprende_app/models/category_model.dart' as AppCategory;
import 'package:emprende_app/models/sale_model.dart'; // Importar el modelo de ventas y detalle de venta
import 'package:emprende_app/services/database_helper.dart';
import 'dart:io';

// Modelo para items del carrito
class CartItem {
  final AppProduct.Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.precioVenta * quantity;
}

class POSScreen extends StatefulWidget {
  // Propiedades recibidas del parent (HomeScreen)
  final List<CartItem> cart;
  final Function(AppProduct.Product) addToCart;
  final VoidCallback clearCart;
  final Function(int, int) updateQuantity;
  final double cartTotal;

  const POSScreen({
    super.key,
    required this.cart,
    required this.addToCart,
    required this.clearCart,
    required this.updateQuantity,
    required this.cartTotal,
  });

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> with SingleTickerProviderStateMixin {
  // Variables de estado propias de POSScreen
  bool _isLoading = true;
  List<AppProduct.Product> _allProducts = [];
  List<AppCategory.Category> _allCategories = [];
  
  // Variables de estado para el proceso de venta
  String? _selectedPaymentMethod;
  final TextEditingController _clientNameController = TextEditingController();

  // TabController para las categorías de productos
  late TabController _categoryTabController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _initializeTabController() {
    if (_allCategories.isNotEmpty) {
      _categoryTabController = TabController(length: _allCategories.length + 1, vsync: this);
    } else {
      // Si no hay categorías, solo mostramos la pestaña "Todos"
      _categoryTabController = TabController(length: 1, vsync: this);
    }
    _categoryTabController.addListener(_handleCategoryTabChange);
  }

  void _handleCategoryTabChange() {
    if (_categoryTabController.indexIsChanging || _categoryTabController.index != _categoryTabController.previousIndex) {
      setState(() {
        if (_categoryTabController.index == 0) {
          _selectedCategoryId = null; // "Todos"
        } else {
          // Asegúrate de que el índice sea válido antes de acceder a _allCategories
          if (_categoryTabController.index - 1 < _allCategories.length) {
            _selectedCategoryId = _allCategories[_categoryTabController.index - 1].id;
          } else {
            _selectedCategoryId = null; // Fallback
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _categoryTabController.removeListener(_handleCategoryTabChange);
    _categoryTabController.dispose();
    _clientNameController.dispose(); // Disponer del controlador de texto
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      final categories = await DatabaseHelper.instance.getAllCategories();
      // Usar mounted para evitar setState después de que el widget se ha desmontado
      if (mounted) {
        setState(() {
          _allProducts = products;
          _allCategories = categories;
          _isLoading = false;
          _initializeTabController(); // Inicializar después de cargar datos
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
  
  List<AppProduct.Product> get _filteredProducts {
    if (_selectedCategoryId == null) {
      return _allProducts;
    }
    return _allProducts.where((p) => p.categoriaId == _selectedCategoryId).toList();
  }

  /// Método para procesar la venta completa.
  /// Crea un objeto Sale, una lista de SaleDetail y llama al DatabaseHelper.
  Future<void> _processSale(String? paymentMethod, String? clientName) async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío. Agregue productos para procesar la venta.')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Mostrar indicador de carga
    });

    try {
      // Crear el objeto Sale
      final sale = Sale(
        total: widget.cartTotal,
        metodoPago: paymentMethod,
        cliente: clientName?.isNotEmpty == true ? clientName : null, // Guarda null si está vacío
        tipo: 'Venta', // Tipo de venta por defecto
        estadoEntrega: 'Entregada', // Estado de entrega por defecto para ventas en POS
      );

      // Crear la lista de SaleDetail a partir del carrito
      final saleDetails = widget.cart.map((item) {
        return SaleDetail(
          productoId: item.product.id!, // Asegúrate de que el ID del producto no sea nulo
          cantidad: item.quantity,
          precioUnitario: item.product.precioVenta,
        );
      }).toList();

      // Llamar al método transaccional en DatabaseHelper
      final saleId = await DatabaseHelper.instance.processSale(sale, saleDetails);

      if (saleId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Venta #$saleId procesada exitosamente!')),
          );
          widget.clearCart(); // Limpiar el carrito después de una venta exitosa
          _loadData(); // Recargar productos para reflejar los cambios de stock
          _clientNameController.clear(); // Limpiar el nombre del cliente
          setState(() {
            _selectedPaymentMethod = null; // Limpiar el método de pago seleccionado
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Eliminar "Exception: " del mensaje de error para una mejor presentación al usuario
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la venta: $errorMessage')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Ocultar indicador de carga
        });
      }
    }
  }

  /// Muestra un diálogo para seleccionar el método de pago y opcionalmente el nombre del cliente.
  Future<void> _showPaymentAndClientDialog() async {
    // Variables temporales para mantener el estado dentro del diálogo antes de confirmar
    String? tempPaymentMethod = _selectedPaymentMethod;
    String? tempClientName = _clientNameController.text;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Usar StatefulBuilder para gestionar el estado del diálogo
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Completar Venta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Cliente (Opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0), // Ajuste de padding
                      ),
                      onChanged: (value) {
                        tempClientName = value; // Actualiza la variable temporal
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0), // Ajuste de padding
                      ),
                      value: tempPaymentMethod,
                      hint: const Text('Seleccione método'),
                      items: <String>['Efectivo', 'Tarjeta', 'Transferencia', 'Crédito'] // Añadido 'Crédito'
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { // Actualiza el estado del diálogo
                          tempPaymentMethod = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total: \$${widget.cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: tempPaymentMethod == null
                      ? null // Deshabilitar botón si no hay método de pago seleccionado
                      : () async {
                          Navigator.of(context).pop(); // Cerrar el diálogo
                          await _processSale(tempPaymentMethod, tempClientName);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary, // Color del botón
                    foregroundColor: Colors.white, // Color del texto del botón
                  ),
                  child: const Text('Confirmar Venta'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Panel de productos (fila superior)
                Expanded(
                  flex: 2, // Ajuste de flex para productos
                  child: Column(
                    children: [
                      _allCategories.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No hay categorías disponibles.'),
                            )
                          : TabBar(
                              controller: _categoryTabController,
                              isScrollable: true,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: [
                                const Tab(text: 'Todos'),
                                ..._allCategories.map((category) => Tab(text: category.nombre)).toList(),
                              ],
                            ),
                      const Divider(height: 1, thickness: 1),
                      Expanded(
                        child: _filteredProducts.isEmpty
                                ? const Center(child: Text('No hay productos en esta categoría.'))
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8.0),
                                    itemCount: _filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = _filteredProducts[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        child: InkWell(
                                          onTap: () => widget.addToCart(product),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 70,
                                                  height: 70,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(8),
                                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: product.imagen != null && product.imagen!.isNotEmpty
                                                        ? Image.file(
                                                              File(product.imagen!),
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) =>
                                                                  Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                                                          )
                                                        : Icon(Icons.inventory_2_outlined, size: 40, color: Theme.of(context).primaryColor),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        product.nombre,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (product.descripcion != null && product.descripcion!.isNotEmpty)
                                                        Text(
                                                          product.descripcion!,
                                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '\$${product.precioVenta.toStringAsFixed(2)}',
                                                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16),
                                                      ),
                                                    ],
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
                // Panel del carrito (fila inferior)
                Expanded(
                  flex: 3, // Ajuste de flex para carrito, ahora más grande
                  child: _buildCartPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildCartPanel() {
    final double bottomSafeAreaPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Carrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                if (widget.cart.isNotEmpty)
                  IconButton(
                    onPressed: widget.clearCart,
                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                    tooltip: 'Limpiar carrito',
                  ),
              ],
            ),
          ),
          Expanded(
            child: widget.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Carrito vacío', style: TextStyle(color: Colors.grey, fontSize: 18)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                child: const Icon(Icons.sell, color: Colors.blueGrey, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.nombre,
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '\$${item.product.precioVenta.toStringAsFixed(2)} c/u',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 24),
                                    onPressed: () => widget.updateQuantity(index, item.quantity - 1),
                                    tooltip: 'Quitar uno',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Container(
                                    width: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 24),
                                    onPressed: () => widget.updateQuantity(index, item.quantity + 1),
                                    tooltip: 'Agregar uno',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (widget.cart.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomSafeAreaPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        '\$${widget.cartTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.cart.isEmpty
                          ? null // Deshabilitar si el carrito está vacío
                          : () async {
                              await _showPaymentAndClientDialog();
                            },
                      icon: const Icon(Icons.payments),
                      label: const Text('PROCESAR VENTA'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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
