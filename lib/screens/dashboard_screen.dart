// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
// Importa fl_chart si lo vas a usar
// import 'package:fl_chart/fl_chart.dart';
// Importa tu database_helper
// import 'package:emprende_app/services/database_helper.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Aquí irá la lógica para cargar datos y construir los gráficos y métricas
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView( // Para permitir scroll si el contenido es largo
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Métricas Clave',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            // Aquí irían tus Cards o Widgets para mostrar métricas
            Card(
              child: ListTile(
                leading: Icon(Icons.show_chart),
                title: Text('Ventas Hoy'),
                subtitle: Text('\$0.00 (0 transacciones)'), // Datos de ejemplo
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Gráficos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10),
            // Aquí irían tus widgets de gráficos (ej. usando fl_chart)
            Container(
              height: 200,
              child: Center(child: Text('Espacio para Gráfico de Ventas')),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // ... más gráficos
          ],
        ),
      ),
    );
  }
}