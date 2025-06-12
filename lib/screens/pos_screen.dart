// lib/screens/pos_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/models/product_model.dart' as AppProduct;
import 'package:emprende_app/models/category_model.dart' as AppCategory;
import 'package:emprende_app/services/database_helper.dart';
import 'dart:io';
// Import Sale and SaleItem models
import 'package:emprende_app/models/sale_model.dart';
import 'package:emprende_app/models/sale_item_model.dart';

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

class _POSScreenState extends State<POSScreen> with TickerProviderStateMixin {
  // Variables de estado propias de POSScreen
  bool _isLoading = true;
  List<AppProduct.Product> _allProducts = [];
  List<AppCategory.Category> _allCategories = [];

  // TabController para las categorías de productos
  TabController? _categoryTabController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _initializeTabController() {
    _categoryTabController?.dispose();

    if (_allCategories.isNotEmpty) {
      _categoryTabController =
          TabController(length: _allCategories.length + 1, vsync: this);
    } else {
      _categoryTabController = TabController(length: 1, vsync: this);
    }
    _categoryTabController!.addListener(_handleCategoryTabChange);
  }

  void _handleCategoryTabChange() {
    if (_categoryTabController != null &&
        (_categoryTabController!.indexIsChanging ||
            _categoryTabController!.index !=
                _categoryTabController!.previousIndex)) {
      setState(() {
        if (_categoryTabController!.index == 0) {
          _selectedCategoryId = null; // "Todos"
        } else {
          if (_categoryTabController!.index - 1 < _allCategories.length) {
            _selectedCategoryId =
                _allCategories[_categoryTabController!.index - 1].id;
          } else {
            _selectedCategoryId = null;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _categoryTabController?.removeListener(_handleCategoryTabChange);
    _categoryTabController?.dispose();
    super.dispose();
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
          _initializeTabController();
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
    return _allProducts
        .where((p) => p.categoriaId == _selectedCategoryId)
        .toList();
  }

  // Método para procesar la venta (CORREGIDO Y MEJORADO)
  Future<void> _processSale() async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Crear el objeto Sale
      final newSale = Sale(
        fecha: DateTime.now(),
        total: widget.cartTotal,
        metodoPago: 'Efectivo',
        cliente: null,
        tipo: 'Venta',
        estadoEntrega: 'Entregada',
        montoPagado: widget.cartTotal,
        saldoPendiente: 0.0,
      );

      // 2. Crear la lista de SaleItem desde el carrito con validación
      final List<SaleItem> saleItems = [];
      for (final cartItem in widget.cart) {
        // **VALIDACIÓN CRÍTICA**
        // Verificamos si el producto en el carrito tiene un ID.
        if (cartItem.product.id == null) {
          throw Exception(
              'Error interno: El producto "${cartItem.product.nombre}" en el carrito no tiene un ID válido.');
        }

        saleItems.add(
          SaleItem(
            saleId: 0, // Será establecido por la base de datos
            productId: cartItem.product.id!, // Seguro usar '!' gracias a la validación
            quantity: cartItem.quantity,
            priceAtSale: cartItem.product.precioVenta,
            subtotal: cartItem.total,
          ),
        );
      }

      // 3. Guardar la venta y sus items en la base de datos
      await DatabaseHelper.instance.createSale(newSale, saleItems);

      // 4. Limpiar el carrito después de la venta exitosa
      widget.clearCart();

      // 5. Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Venta procesada exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error detallado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la venta: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Ocultar indicador de carga y refrescar datos
      if (mounted) {
        setState(() => _isLoading = false);
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Panel de productos (fila superior)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      if (_categoryTabController != null)
                        _allCategories.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No hay categorías disponibles.'),
                              )
                            : TabBar(
                                controller: _categoryTabController,
                                isScrollable: true,
                                labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: [
                                  const Tab(text: 'Todos'),
                                  ..._allCategories
                                      .map((category) =>
                                          Tab(text: category.nombre))
                                      .toList(),
                                ],
                              ),
                      const Divider(height: 1, thickness: 1),
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? const Center(
                                child:
                                    Text('No hay productos en esta categoría.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 0.0),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.1),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: product.imagen != null &&
                                                        product
                                                            .imagen!.isNotEmpty
                                                    ? Image.file(
                                                        File(product.imagen!),
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            Icon(
                                                                Icons
                                                                    .broken_image,
                                                                size: 40,
                                                                color: Colors
                                                                    .grey[400]),
                                                      )
                                                    : Icon(
                                                        Icons
                                                            .inventory_2_outlined,
                                                        size: 40,
                                                        color: Theme.of(context)
                                                            .primaryColor),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.nombre,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (product.descripcion !=
                                                          null &&
                                                      product.descripcion!
                                                          .isNotEmpty)
                                                    Text(
                                                      product.descripcion!,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600]),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '\$${product.precioVenta.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .green[700],
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        'Stock: ${product.stock}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: product
                                                                      .stock <=
                                                                  product
                                                                      .stockAlerta
                                                              ? Colors.red
                                                              : Colors
                                                                  .grey[600],
                                                          fontWeight: product
                                                                      .stock <=
                                                                  product
                                                                      .stockAlerta
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                        ),
                                                      ),
                                                    ],
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
                  flex: 3,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Theme.of(context).primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Carrito',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
                        Icon(Icons.shopping_cart_outlined,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Carrito vacío',
                            style: TextStyle(color: Colors.grey, fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text('Toca un producto para agregarlo',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 4.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                child: const Icon(Icons.sell,
                                    color: Colors.blueGrey, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '\$${item.product.precioVenta.toStringAsFixed(2)} c/u',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red,
                                        size: 24),
                                    onPressed: () => widget.updateQuantity(
                                        index, item.quantity - 1),
                                    tooltip: 'Quitar uno',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Container(
                                    width: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Colors.green, size: 24),
                                    onPressed: () => widget.updateQuantity(
                                        index, item.quantity + 1),
                                    tooltip: 'Agregar uno',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
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
              padding: EdgeInsets.fromLTRB(
                  16.0, 16.0, 16.0, 16.0 + bottomSafeAreaPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
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
                      const Text('Total:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        '\$${widget.cartTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _processSale,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white)))
                          : const Icon(Icons.payments),
                      label:
                          Text(_isLoading ? 'PROCESANDO...' : 'PROCESAR VENTA'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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