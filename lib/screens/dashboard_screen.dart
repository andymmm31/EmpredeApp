// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:emprende_app/services/database_helper.dart';
import 'package:emprende_app/models/product_model.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _todayStats = {};
  Map<String, dynamic> _weekStats = {};
  List<Product> _lowStockProducts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar estadísticas generales
      final stats = await DatabaseHelper.instance.getInventoryStats();

      // Cargar estadísticas de hoy
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
      final todayEnd = DateTime.now();
      final todayStats =
          await DatabaseHelper.instance.getSalesSummaryByDateRange(
        startDate: todayStart,
        endDate: todayEnd,
      );

      // Cargar estadísticas de la semana
      final weekStart = DateTime.now().subtract(Duration(days: 7));
      final weekStats =
          await DatabaseHelper.instance.getSalesSummaryByDateRange(
        startDate: weekStart,
        endDate: todayEnd,
      );

      // Cargar productos con stock bajo
      final lowStock = await DatabaseHelper.instance.getLowStockProducts();

      if (mounted) {
        setState(() {
          _stats = stats;
          _todayStats = todayStats;
          _weekStats = weekStats;
          _lowStockProducts = lowStock;
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // SOLUCIÓN 1: Agregar SafeArea para evitar overlap con status bar
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildKPICards(),
                const SizedBox(height: 24),
                _buildSalesCharts(),
                const SizedBox(height: 24),
                _buildInventorySection(),
                const SizedBox(height: 24),
                _buildLowStockAlert(),
                // SOLUCIÓN 2: Agregar padding extra al final para evitar overlap con bottom navigation
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formatter = DateFormat('EEEE, d MMMM', 'es');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          formatter.format(DateTime.now()),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildKPICards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de Hoy',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0, // Más altura para mostrar todo el contenido
          children: [
            _buildKPICard(
              'Ventas Hoy',
              '\$${_todayStats['salesTotal']?.toStringAsFixed(2) ?? '0.00'}',
              '${_todayStats['salesCount'] ?? 0} transacciones',
              Icons.point_of_sale,
              Colors.green,
            ),
            _buildKPICard(
              'Cotizaciones Hoy',
              '\$${_todayStats['quotesTotal']?.toStringAsFixed(2) ?? '0.00'}',
              '${_todayStats['quotesCount'] ?? 0} cotizaciones',
              Icons.request_quote,
              Colors.blue,
            ),
            _buildKPICard(
              'Ventas Semana',
              '\$${_weekStats['salesTotal']?.toStringAsFixed(2) ?? '0.00'}',
              '${_weekStats['salesCount'] ?? 0} ventas',
              Icons.trending_up,
              Colors.orange,
            ),
            _buildKPICard(
              'Pendientes',
              '${_stats['pendingSalesCount'] ?? 0}',
              'Por entregar: ${_stats['toDeliverSalesCount'] ?? 0}',
              Icons.pending_actions,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reducido padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reducido padding del icono
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 20), // Icono más pequeño
                ),
                if (value != '0' && value != '\$0.00')
                  Icon(Icons.arrow_upward, color: Colors.green, size: 14),
              ],
            ),
            const SizedBox(height: 8), // Espaciado fijo
            
            // Valor principal - más prominente
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith( // Cambiado de headlineSmall
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Título
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Subtítulo
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas de Ventas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ventas vs Cotizaciones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: _buildSimpleBarChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleBarChart() {
    final double salesTotal = _stats['totalSalesValue'] ?? 0.0;
    final double quotesTotal = _stats['totalQuotesValue'] ?? 0.0;
    final maxValue = math.max(salesTotal, quotesTotal);

    if (maxValue == 0) {
      return Center(
        child: Text(
          'No hay datos para mostrar',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar('Ventas', salesTotal, maxValue, Colors.green),
        _buildBar('Cotizaciones', quotesTotal, maxValue, Colors.blue),
      ],
    );
  }

  Widget _buildBar(String label, double value, double maxValue, Color color) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: math.max(150 * percentage, 10), // SOLUCIÓN 5: Altura mínima
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildInventorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado del Inventario',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInventoryCard(
                'Total Productos',
                '${_stats['totalProducts'] ?? 0}',
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInventoryCard(
                'Valor Inventario',
                '\$${(_stats['totalInventoryValue'] ?? 0.0).toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInventoryCard(
                'Stock Bajo',
                '${_stats['lowStockProducts'] ?? 0}',
                Icons.warning,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInventoryCard(
                'Categorías',
                '${_stats['totalCategories'] ?? 0}',
                Icons.category,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SOLUCIÓN 6: Usar FittedBox para texto largo
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    if (_lowStockProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Alertas de Stock Bajo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                // SOLUCIÓN 7: Verificar si DefaultTabController existe
                try {
                  DefaultTabController.of(context).animateTo(0);
                } catch (e) {
                  // Si no hay TabController, mostrar un mensaje o navegar diferente
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navegando a inventario...')),
                  );
                }
              },
              child: const Text('Ver todos'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: _lowStockProducts.take(5).map((product) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                title: Text(
                  product.nombre,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Stock: ${product.stock} / Alerta: ${product.stockAlerta}',
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.stock == 0 ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product.stock == 0 ? 'Sin Stock' : 'Stock Bajo',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}