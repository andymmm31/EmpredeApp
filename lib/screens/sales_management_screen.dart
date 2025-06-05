// lib/screens/sales_management_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
// Importa tu database_helper y modelos de venta cuando los necesites
// import 'package:emprende_app/services/database_helper.dart';
// import 'package:emprende_app/models/sale_model.dart';
// import 'package:emprende_app/screens/sale_detail_screen.dart';

class SalesManagementScreen extends StatefulWidget {
  const SalesManagementScreen({super.key});

  @override
  State<SalesManagementScreen> createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends State<SalesManagementScreen> {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'Todos';
  String _selectedStatus = 'Todos';

  // bool _isLoading = false; // Para un indicador de carga
  // List<Sale> _sales = []; // Deberías cargar esto desde la DB

  @override
  void initState() {
    super.initState();
    // _loadSalesHistory(); // Cargar historial inicial
  }

  // Future<void> _loadSalesHistory() async {
  //   if (!mounted) return;
  //   setState(() {
  //     _isLoading = true;
  //   });
  //   try {
  //     // final salesFromDb = await DatabaseHelper.instance.getSalesByDateRangeAndFilters(
  //     //   startDate: _startDate,
  //     //   endDate: _endDate,
  //     //   typeFilter: _selectedType,
  //     //   statusFilter: _selectedStatus,
  //     // );
  //     // if (!mounted) return;
  //     // setState(() {
  //     //   _sales = salesFromDb;
  //     // });
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error al cargar historial: $e')),
  //     );
  //   } finally {
  //     if (!mounted) return;
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) { // Primero, asegúrate de que picked no sea null
      if (picked.start != _startDate || picked.end != _endDate) {
        if (!mounted) return;
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
        });
        // _loadSalesHistory(); // Llama para recargar con las nuevas fechas
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.calendar_today, size: 18),
                            label: Text('Seleccionar Fechas'),
                            onPressed: () => _selectDateRange(context),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12)
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                     Center(
                      child: Text(
                        'Desde: ${DateFormat.yMd().format(_startDate)} - Hasta: ${DateFormat.yMd().format(_endDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
                            value: _selectedType,
                            items: ['Todos', 'Venta', 'Cotizacion']
                                .map((label) => DropdownMenuItem(
                                      value: label, // value primero
                                      child: Text(label), // child después
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedType = value;
                              });
                              // _loadSalesHistory();
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                            value: _selectedStatus,
                            items: ['Todos', 'Pendiente', 'Por Entregar', 'Entregada', 'Cancelada']
                                .map((label) => DropdownMenuItem(
                                      value: label, // value primero
                                      child: Text(label), // child después
                                    ))
                                .toList(),
                            onChanged: (value) {
                               if (value == null) return;
                              setState(() {
                                _selectedStatus = value;
                              });
                              // _loadSalesHistory();
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // ElevatedButton(
                    //   onPressed: _loadSalesHistory,
                    //   child: Text('🔍 Filtrar'),
                    // )
                  ],
                ),
              ),
            ),
          ),
          // if (_isLoading)
          //   Padding(
          //     padding: const EdgeInsets.all(16.0),
          //     child: Center(child: CircularProgressIndicator()),
          //   )
          // else if (_sales.isEmpty)
          //  Expanded(
          //     child: Center(child: Text('No se encontraron ventas/cotizaciones con estos filtros.'))
          //   )
          // else
            Expanded(
              // child: ListView.builder(
              //   itemCount: _sales.length,
              //   itemBuilder: (context, index) {
              //     final sale = _sales[index];
              //     return Card(
              //       margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //       child: ListTile(
              //         leading: Icon(sale.tipo == 'Venta' ? Icons.receipt : Icons.request_quote_outlined),
              //         title: Text('${sale.tipo} ID: #${sale.id}'),
              //         subtitle: Text('Cliente: ${sale.cliente ?? "N/A"} - Total: \$${sale.total.toStringAsFixed(2)}\nEstado: ${sale.estadoEntrega} - ${DateFormat.yMd().add_jm().format(sale.fecha)}'),
              //         isThreeLine: true,
              //         trailing: Icon(Icons.arrow_forward_ios),
              //         onTap: () {
                          // Navigator.of(context).push(
                          //   MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id!)) // Necesitas crear SaleDetailScreen
                          // ).then((_) => _loadSalesHistory()); // Recargar si se vuelve y algo cambió
              //         },
              //       ),
              //     );
              //   },
              // ),
              // Placeholder mientras no hay datos:
              child: ListView.builder(
                itemCount: 5, 
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: Icon(index.isEven ? Icons.receipt : Icons.request_quote_outlined),
                      title: Text('Ejemplo ID: #${index + 1}'),
                      subtitle: Text('Cliente: Cliente Ejemplo - Total: \$${(index + 1) * 50}.00\nEstado: Pendiente - ${DateFormat.yMd().format(DateTime.now())}'),
                      isThreeLine: true,
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {},
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