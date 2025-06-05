import 'package:flutter/material.dart';
import 'package:emprende_app/screens/welcome_screen.dart';
// import 'package:provider/provider.dart'; // Si usas Provider
// import 'package:flutter_riverpod/flutter_riverpod.dart'; // Si usas Riverpod
// import 'package:emprende_app_mobile/providers/product_provider.dart'; // Ejemplo Provider

void main() {
  // WidgetsFlutterBinding.ensureInitialized(); // Asegúrate de que los bindings estén inicializados si usas plugins antes de runApp
  
  // Si usas Provider:
  // runApp(
  //   MultiProvider(
  //     providers: [
  //       ChangeNotifierProvider(create: (_) => ProductProvider()),
  //       // ... otros providers
  //     ],
  //     child: EmprendeAppMobile(),
  //   ),
  // );

  // Si usas Riverpod:
  // runApp(
  //  ProviderScope(
  //    child: EmprendeAppMobile(),
  //  ),
  // );
  
  // Sin gestión de estado avanzada (para empezar):
  runApp(EmprendeAppMobile());
}

class EmprendeAppMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmprendeApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFf0f0f0), // Similar a tu bg
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[700], // Similar a #2c3e50
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.amber, // Color de acento
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Botones principales
            foregroundColor: Colors.white,
          )
        ),
        // Puedes definir más temas para Text, Card, etc.
      ),
      debugShowCheckedModeBanner: false, // Oculta el banner de debug
      home: WelcomeScreen(),
    );
  }
}