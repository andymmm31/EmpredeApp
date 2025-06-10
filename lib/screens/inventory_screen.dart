// lib/screens/inventory_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:emprende_app/models/category_model.dart';
import 'package:emprende_app/screens/product_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with TickerProviderStateMixin {
  late Future<Map<String, List<Product>>> _groupedProductsFuture;
  late Future<Map<String, dynamic>> _statsFuture;
  late TabController _tabController;
  
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _groupedProductsFuture = _getGroupedProducts();
      _statsFuture = DatabaseHelper.instance.getInventoryStats();
    });
  }

  Future<Map<String, List<Product>>> _getGroupedProducts() async {
    List<Product> products;
    
    if (_searchQuery.isNotEmpty) {
      products = await DatabaseHelper.instance.searchProducts(_searchQuery);
    } else {
      products = await DatabaseHelper.instance.getAllProducts();
    }

    final categories = await DatabaseHelper.instance.getAllCategories();
    final Map<int, String> categoryMap = {for (var c in categories) c.id!: c.nombre};
    
    final Map<String, List<Product>> grouped = {};
    for (var product in products) {
      final categoryName = categoryMap[product.categoriaId] ?? 'Sin Categoría';
      
      // Aplicar filtro de categoría
      if (_selectedFilter == 'Todos' || _selectedFilter == categoryName) {
        (grouped[categoryName] ??= []).add(product);
      }
    }
    return grouped;
  }

  void _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
    if (result == true) {
      _refreshData();
    }
  }

  void _showStockAdjustDialog(Product product) {
    final TextEditingController stockController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajustar Stock: ${product.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock actual: ${product.stock}'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _adjustStock(product, -1),
                    child: Text('-1'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[100]),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _adjustStock(product, 1),
                    child: Text('+1'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[100]),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final adjustment = int.tryParse(stockController.text);
              if (adjustment != null) {
                _adjustStock(product, adjustment);
              }
              Navigator.pop(context);
            },
            child: Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _adjustStock(Product product, int adjustment) async {
    await DatabaseHelper.instance.adjustStock(product.id!, adjustment);
    _refreshData();
    Navigator.pop(context);
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        
        final stats = snapshot.data!;
        return Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Resumen del Inventario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Productos', stats['totalProducts'].toString(), Icons.inventory),
                    _buildStatItem('Stock Bajo', stats['lowStockProducts'].toString(), Icons.warning, Colors.orange),
                    _buildStatItem('Categorías', stats['totalCategories'].toString(), Icons.category),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Valor Total: \$${stats['totalInventoryValue'].toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 30),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar productos...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      _refreshData();
                    },
                  )
                : null,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _refreshData();
            },
          ),
          SizedBox(height: 12),
          FutureBuilder<List<Category>>(
            future: DatabaseHelper.instance.getAllCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              
              final categories = ['Todos'] + snapshot.data!.map((c) => c.nombre).toList();
              
              return DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: InputDecoration(
                  labelText: 'Filtrar por categoría',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  _refreshData();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsTab() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: FutureBuilder<Map<String, List<Product>>>(
            future: _groupedProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error al cargar inventario: ${snapshot.error}', style: TextStyle(color: Colors.red)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 20),
                      Text('No se encontraron productos', style: TextStyle(fontSize: 22, color: Colors.grey[700])),
                      SizedBox(height: 10),
                      Text(_searchQuery.isNotEmpty ? 'Intenta con otra búsqueda' : 'Presiona el botón + para agregar tu primer producto', 
                           style: TextStyle(fontSize: 16, color: Colors.grey)),
                      if (_searchQuery.isEmpty) ...[
                        SizedBox(height: 30),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Agregar Producto'),
                          onPressed: () => _navigateAndRefresh(ProductFormScreen()),
                          style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final groupedProducts = snapshot.data!;
              final categories = groupedProducts.keys.toList();

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final categoryName = categories[index];
                    final productsInCategory = groupedProducts[categoryName]!;
                    return ExpansionTile(
                      title: Text(categoryName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text('${productsInCategory.length} productos'),
                      initiallyExpanded: categories.length <= 2,
                      children: productsInCategory.map((product) {
                        bool isLowStock = product.stock <= product.stockAlerta;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: product.imagen != null && product.imagen!.isNotEmpty ? FileImage(File(product.imagen!)) : null,
                            child: product.imagen == null || product.imagen!.isEmpty ? Icon(Icons.sell) : null,
                          ),
                          title: Text(product.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Precio: \$${product.precioVenta.toStringAsFixed(2)} | Stock: ${product.stock}'),
                              if (product.descripcion != null && product.descripcion!.isNotEmpty)
                                Text(product.descripcion!, style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLowStock) Icon(Icons.warning_amber, color: Colors.orange),
                              IconButton(
                                icon: Icon(Icons.edit_note),
                                onPressed: () => _showStockAdjustDialog(product),
                                tooltip: 'Ajustar Stock',
                              ),
                            ],
                          ),
                          onTap: () => _navigateAndRefresh(ProductFormScreen(product: product)),
                        );
                      }).toList(),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockTab() {
    return FutureBuilder<List<Product>>(
      future: DatabaseHelper.instance.getLowStockProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                SizedBox(height: 20),
                Text('¡Perfecto!', style: TextStyle(fontSize: 22, color: Colors.green[700])),
                Text('No hay productos con stock bajo', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        final lowStockProducts = snapshot.data!;
        return ListView.builder(
          itemCount: lowStockProducts.length,
          itemBuilder: (context, index) {
            final product = lowStockProducts[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.orange[50],
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.warning, color: Colors.white),
                ),
                title: Text(product.nombre),
                subtitle: Text('Stock: ${product.stock} (Alerta: ${product.stockAlerta})'),
                trailing: ElevatedButton(
                  onPressed: () => _showStockAdjustDialog(product),
                  child: Text('Reabastecer'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                onTap: () => _navigateAndRefresh(ProductFormScreen(product: product)),
              ),
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
        title: Text('Inventario'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.inventory), text: 'Productos'),
            Tab(icon: Icon(Icons.warning), text: 'Stock Bajo'),
            Tab(icon: Icon(Icons.category), text: 'Categorías'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Resumen
          SingleChildScrollView(
            child: Column(
              children: [
                _buildStatsCard(),
                // Aquí podrías agregar más widgets de resumen como gráficos
              ],
            ),
          ),
          // Tab Productos
          _buildAllProductsTab(),
          // Tab Stock Bajo
          _buildLowStockTab(),
          // Tab Categorías (placeholder por ahora)
          Center(child: Text('Gestión de Categorías\n(Por implementar)', textAlign: TextAlign.center)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndRefresh(ProductFormScreen()),
        tooltip: 'Nuevo Producto',
        child: Icon(Icons.add),
      ),
    );
  }
}