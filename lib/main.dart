// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';

// Importa los diferentes backends para la base de datos
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Importa las pantallas principales
import 'package:emprende_app/screens/welcome_screen.dart';
import 'package:emprende_app/screens/home_screen.dart';

Future<void> main() async {
  // Siempre inicializa los bindings primero
  WidgetsFlutterBinding.ensureInitialized();

  // Configura el factory de la base de datos SOLO si la plataforma es WEB
  if (kIsWeb) {
    // Si la plataforma es WEB, usa el factory de la base de datos para web.
    databaseFactory = databaseFactoryFfiWeb;
  }
  // Para Android, no se necesita hacer nada aquí. sqflite funciona de forma nativa.
  // Para iOS, tampoco se necesita hacer nada.

  // Ahora, corre la aplicación
  runApp(const EmprendeAppMobile());
}

class EmprendeAppMobile extends StatelessWidget {
  const EmprendeAppMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmprendeApp',

      // Configuración de localización
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés como fallback
      ],
      locale: const Locale('es', 'ES'), // Establecer español por defecto

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFf0f0f0),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[700],
          foregroundColor: Colors.white,
        ),
        colorScheme:
            ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.amber,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        )),
      ),
      debugShowCheckedModeBanner: false,
      // Pantalla inicial
      home: WelcomeScreen(),
      // Define las rutas principales de navegación
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
