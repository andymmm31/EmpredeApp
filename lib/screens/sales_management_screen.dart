// lib/screens/sales_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/sale_model.dart';
import 'package:emprende_app/screens/sale_detail_screen.dart';

class SalesManagementScreen extends StatefulWidget {
  const SalesManagementScreen({super.key});

  @override
  State<SalesManagementScreen> createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends State<SalesManagementScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'Todos';
  String _selectedStatus = 'Todos';

  bool _isLoading = false;
  List<Sale> _sales = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadSalesHistory();
  }

  Future<void> _loadSalesHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final salesFromDb =
          await DatabaseHelper.instance.getSalesByDateRangeAndFilters(
        startDate: _startDate,
        endDate: _endDate,
        typeFilter: _selectedType,
        statusFilter: _selectedStatus,
      );

      double totalVentas = 0;
      double totalCotizaciones = 0;
      int countVentas = 0;
      int countCotizaciones = 0;

      for (var sale in salesFromDb) {
        if (sale.tipo == 'Venta') {
          totalVentas += sale.total;
          countVentas++;
        } else {
          totalCotizaciones += sale.total;
          countCotizaciones++;
        }
      }

      if (!mounted) return;
      setState(() {
        _sales = salesFromDb;
        _summary = {
          'totalVentas': totalVentas,
          'totalCotizaciones': totalCotizaciones,
          'countVentas': countVentas,
          'countCotizaciones': countCotizaciones,
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar historial: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      if (!mounted) return;
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadSalesHistory();
    }
  }

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

  IconData _getTypeIcon(String tipo) {
    return tipo == 'Venta' ? Icons.receipt_long : Icons.request_quote;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ventas'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard(
                  'Ventas',
                  _summary['countVentas'] ?? 0,
                  _summary['totalVentas'] ?? 0.0,
                  Colors.green,
                ),
                _buildSummaryCard(
                  'Cotizaciones',
                  _summary['countCotizaciones'] ?? 0,
                  _summary['totalCotizaciones'] ?? 0.0,
                  Colors.blue,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rango de fechas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Tipo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
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
                              _loadSalesHistory();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Estado',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            value: _selectedStatus,
                            items: [
                              'Todos',
                              'Pendiente',
                              'Por Entregar',
                              'Entregada',
                              'Cancelada'
                            ]
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
                              _loadSalesHistory();
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron registros',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta cambiar los filtros',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSalesHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          itemCount: _sales.length,
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
                            return _buildSaleCard(sale);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, double total, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // MÉTODO _buildSaleCard COMPLETAMENTE CORREGIDO Y REESTRUCTURADO
  // ================================================================
  Widget _buildSaleCard(Sale sale) {
    final statusColor = _getStatusColor(sale.estadoEntrega);
    final typeColor = sale.tipo == 'Venta' ? Colors.green : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => SaleDetailScreen(saleId: sale.id!),
                ),
              )
              .then((_) => _loadSalesHistory());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Columna del Icono
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(25), // 10% de opacidad
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(sale.tipo),
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),
              
              // Columna principal con toda la información (expandida)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila superior: Título y Estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${sale.tipo} #${sale.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            sale.estadoEntrega,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Cliente
                    Text(
                      'Cliente: ${sale.cliente ?? "Sin especificar"}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Fila inferior: Fecha y Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd/MM/yy HH:mm').format(sale.fecha),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        Text(
                          '\$${sale.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Icono de la flecha a la derecha
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}