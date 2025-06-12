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
  
  // Nuevas variables para los gráficos
  List<Map<String, dynamic>> _dailySales = [];
  List<Map<String, dynamic>> _topProducts = [];
  
  // Variables para el selector de rango de fechas
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

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
      final weekStart = DateTime.now().subtract(const Duration(days: 7));
      final weekStats =
          await DatabaseHelper.instance.getSalesSummaryByDateRange(
        startDate: weekStart,
        endDate: todayEnd,
      );

      // Cargar productos con stock bajo
      final lowStock = await DatabaseHelper.instance.getLowStockProducts();
      
      // Cargar datos para los nuevos gráficos
      final dailySales = await DatabaseHelper.instance.getDailySales(
        startDate: _selectedDateRange.start,
        endDate: _selectedDateRange.end,
      );
      
      final topProducts = await DatabaseHelper.instance.getTopSellingProductsByPeriod(
        startDate: _selectedDateRange.start,
        endDate: _selectedDateRange.end,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _stats = stats;
          _todayStats = todayStats;
          _weekStats = weekStats;
          _lowStockProducts = lowStock;
          _dailySales = dailySales;
          _topProducts = topProducts;
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      locale: const Locale('es', 'ES'),
    );
    
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadDashboardData();
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
                _buildDateRangeSelector(),
                const SizedBox(height: 16),
                _buildDailySalesChart(),
                const SizedBox(height: 24),
                _buildTopProductsChart(),
                const SizedBox(height: 24),
                _buildSalesCharts(),
                const SizedBox(height: 24),
                _buildInventorySection(),
                const SizedBox(height: 24),
                _buildLowStockAlert(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final formatter = DateFormat('dd/MM/yyyy');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período de Análisis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatter.format(_selectedDateRange.start)} - ${formatter.format(_selectedDateRange.end)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range),
              label: const Text('Cambiar'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySalesChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventas Diarias',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evolución de Ventas por Día',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: _buildDailySalesLineChart(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailySalesLineChart() {
    if (_dailySales.isEmpty) {
      return Center(
        child: Text(
          'No hay ventas en el período seleccionado',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final maxValue = _dailySales
        .map((sale) => (sale['daily_total'] as num).toDouble())
        .reduce(math.max);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(300, _dailySales.length * 40.0),
        child: CustomPaint(
          size: Size(double.infinity, 180),
          painter: LineChartPainter(_dailySales, maxValue),
        ),
      ),
    );
  }

  Widget _buildTopProductsChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos Más Vendidos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top 5 Productos por Cantidad Vendida',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                _buildTopProductsList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductsList() {
    if (_topProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No hay productos vendidos en el período seleccionado',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final maxQuantity = _topProducts.isNotEmpty
        ? _topProducts
            .map((product) => (product['total_quantity'] as num).toDouble())
            .reduce(math.max)
        : 1.0;

    return Column(
      children: _topProducts.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        final quantity = (product['total_quantity'] as num).toDouble();
        final revenue = (product['total_revenue'] as num).toDouble();
        final percentage = maxQuantity > 0 ? (quantity / maxQuantity) : 0.0; // Evitar división por cero

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${index + 1}. ${product['product_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${quantity.toInt()} ud.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getProductColor(index),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${revenue.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getProductColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
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
          childAspectRatio: 1.0,
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (value != '0' && value != '\$0.00')
                  Icon(Icons.arrow_upward, color: Colors.green, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

  // Reemplaza este método en lib/screens/dashboard_screen.dart

Widget _buildBar(String label, double value, double maxValue, Color color) {
  final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
  // Altura máxima para las barras, puedes ajustarla si quieres el gráfico más alto o bajo.
  const double maxBarHeight = 150.0;

  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min, // <-- Añadido: Hace que la columna ocupe el mínimo espacio vertical.
    children: [
      Text(
        '\$${value.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Un poco más pequeño
      ),
      const SizedBox(height: 4), // <-- Reducido de 8 a 4
      Container(
        width: 80,
        // Usamos 'maxBarHeight' para la altura, no 150.
        height: math.max(maxBarHeight * percentage, 10), // El mínimo de 10 es para que las barras de 0 se vean.
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      const SizedBox(height: 4), // <-- Reducido de 8 a 4
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
                try {
                  DefaultTabController.of(context).animateTo(0);
                } catch (e) {
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

// Custom Painter para el gráfico de líneas
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;

  LineChartPainter(this.data, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    // Calcular puntos
    for (int i = 0; i < data.length; i++) {
      final value = (data[i]['daily_total'] as num).toDouble();
      // Asegurar que data.length > 1 para evitar división por cero si solo hay un punto
      final x = (data.length > 1) ? (i / (data.length - 1)) * size.width : size.width / 2;
      // Asegurar que maxValue no sea cero para evitar división por cero
      final y = size.height - (maxValue > 0 ? (value / maxValue) * size.height : size.height);
      points.add(Offset(x, y));
    }

    // Crear path para la línea
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      
      // Completar el path para rellenar el área
      if (points.length > 1) {
        fillPath.lineTo(points.last.dx, size.height);
      } else { // Si solo hay un punto
        fillPath.lineTo(points.first.dx, size.height);
      }
      fillPath.close();
    }

    // Dibujar área rellena
    canvas.drawPath(fillPath, fillPaint);

    // Dibujar línea
    canvas.drawPath(path, paint);

    // Dibujar puntos
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Dibujar etiquetas de fechas (opcional, cada ciertos puntos)
    final textPainter = TextPainter();

    // Ajustar el paso para las etiquetas para no sobreponerlas
    int step = 1;
    if (points.length > 5) {
      step = (points.length / 5).ceil(); // Mostrar unas 5 etiquetas máximo
    }
    
    for (int i = 0; i < points.length; i += step) {
      // Asegurarse de que data[i] existe (por si step es muy grande y i excede el límite)
      if (i < data.length) {
          final date = DateTime.parse(data[i]['date']);
          final dateStr = DateFormat('dd/MM').format(date);
          
          textPainter.text = TextSpan(
            text: dateStr,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          );
          textPainter.layout();
          
          final textX = points[i].dx - textPainter.width / 2;
          final textY = size.height + 5;
          
          // No dibujar la etiqueta si se sale mucho del ancho del gráfico
          if (textX >= -textPainter.width / 2 && textX <= size.width - textPainter.width / 2) {
             textPainter.paint(canvas, Offset(textX, textY));
          }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}