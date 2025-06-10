// lib/screens/sales_management_screen.dart

import 'package:flutter/material.dart';
import 'package:emprende_app/models/sale_model.dart';
import 'package:emprende_app/models/product_model.dart' as app_product; // Cambiado a snake_case
import 'package:emprende_app/services/database_helper.dart';
import 'package:intl/intl.dart'; // Para formatear fechas y monedas

class SalesManagementScreen extends StatefulWidget {
  const SalesManagementScreen({super.key});

  @override
  State<SalesManagementScreen> createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends State<SalesManagementScreen> {
  bool _isLoading = true;
  List<Sale> _sales = []; // Ahora usaremos _sales directamente
  
  // Variables de estado para los filtros
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'Todos'; // 'Todos', 'Venta', 'Cotizacion'
  String _selectedStatus = 'Todos'; // 'Todos', 'Pendiente', 'Por Entregar', 'Entregada', 'Cancelada'

  @override
  void initState() {
    super.initState();
    _loadSalesHistory(); // Cargar historial inicial con los filtros por defecto
  }

  Future<void> _loadSalesHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final salesFromDb = await DatabaseHelper.instance.getSalesByDateRangeAndFilters(
        startDate: _startDate,
        endDate: _endDate,
        typeFilter: _selectedType == 'Todos' ? null : _selectedType,
        statusFilter: _selectedStatus == 'Todos' ? null : _selectedStatus,
      );
      if (!mounted) return;
      setState(() {
        _sales = salesFromDb;
      });
      // DEBUG: Imprime cuántas ventas se cargaron
      print('Ventas cargadas: ${_sales.length}'); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
      // DEBUG: Imprime el error completo en la consola
      print('Error en _loadSalesHistory: $e'); 
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'Seleccionar Rango de Fechas',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      saveText: 'Guardar',
    );
    if (picked != null) {
      if (picked.start != _startDate || picked.end != _endDate) {
        if (!mounted) return;
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
        });
        _loadSalesHistory(); // Llama para recargar con las nuevas fechas
      }
    }
  }

  // Método para mostrar los detalles de una venta en un diálogo
  Future<void> _showSaleDetails(Sale sale) async {
    List<SaleDetail> details = [];
    List<Map<String, dynamic>> productDetails = []; // Para almacenar nombre del producto y detalles

    try {
      details = await DatabaseHelper.instance.getSaleDetailsBySaleId(sale.id!);
      for (var detail in details) {
        // Usando el alias app_product en lugar de AppProduct
        final product = await DatabaseHelper.instance.getProductById(detail.productoId);
        if (product != null) {
          productDetails.add({
            'nombre': product.nombre,
            'cantidad': detail.cantidad,
            'precioUnitario': detail.precioUnitario,
            'subtotal': detail.cantidad * detail.precioUnitario,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar detalles de la venta: $e')),
        );
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Detalles de Venta #${sale.id}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.fecha)}'),
                  Text('Total: \$${sale.total.toStringAsFixed(2)}'),
                  if (sale.metodoPago != null && sale.metodoPago!.isNotEmpty) Text('Método de Pago: ${sale.metodoPago}'),
                  if (sale.cliente != null && sale.cliente!.isNotEmpty) Text('Cliente: ${sale.cliente}'),
                  Text('Tipo: ${sale.tipo}'),
                  Text('Estado de Entrega: ${sale.estadoEntrega}'),
                  const Divider(),
                  const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (productDetails.isEmpty)
                    const Text('No hay productos para esta venta.')
                  else
                    ...productDetails.map((detail) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                        child: Text(
                          '${detail['nombre']} x${detail['cantidad']} @ \$${detail['precioUnitario'].toStringAsFixed(2)} = \$${detail['subtotal'].toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cerrar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Helper para obtener el color del estado de entrega
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'Por Entregar':
        return Colors.blue;
      case 'Entregada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () => _selectDateRange(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 18),
                          SizedBox(width: 8),
                          Text('Seleccionar Fechas'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Desde: ${DateFormat.yMd().format(_startDate)} - Hasta: ${DateFormat.yMd().format(_endDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            value: _selectedType,
                            items: ['Todos', 'Venta', 'Cotizacion']
                                .map((label) => DropdownMenuItem(
                                      value: label,
                                      child: Text(label),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedType = value;
                              });
                              _loadSalesHistory(); // Recargar al cambiar el tipo
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Estado',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            value: _selectedStatus,
                            items: ['Todos', 'Pendiente', 'Por Entregar', 'Entregada', 'Cancelada']
                                .map((label) => DropdownMenuItem(
                                      value: label,
                                      child: Text(label),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedStatus = value;
                              });
                              _loadSalesHistory(); // Recargar al cambiar el estado
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Estructura de la expresión ternaria corregida
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_sales.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No se encontraron ventas/cotizaciones con estos filtros.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _sales.length,
                itemBuilder: (context, index) {
                  final sale = _sales[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _showSaleDetails(sale),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${sale.tipo} #${sale.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent),
                                ),
                                Text(
                                  '\$${sale.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.fecha)}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            if (sale.cliente != null && sale.cliente!.isNotEmpty)
                              Text(
                                'Cliente: ${sale.cliente}',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                // Corrección para la advertencia 'withOpacity' is deprecated
                                color: _getStatusColor(sale.estadoEntrega).withAlpha((255 * 0.1).round()),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Estado: ${sale.estadoEntrega}',
                                style: TextStyle(
                                  color: _getStatusColor(sale.estadoEntrega),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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
    );
  }
}