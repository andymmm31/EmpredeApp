// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es web

// Importa los diferentes backends para la base de datos
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:emprende_app/screens/welcome_screen.dart'; // Tu pantalla de bienvenida

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
  runApp(EmprendeAppMobile());
}

class EmprendeAppMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmprendeApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFf0f0f0),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[700],
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Colors.amber,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          )
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}