import 'package:flutter/material.dart';
import 'package:emprende_app/screens/home_screen.dart'; // Asume que tienes HomeScreen

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Opcional: Navegar automáticamente después de un tiempo
    // Future.delayed(Duration(seconds: 3), () {
    //   _navigateToHome();
    // });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2c3e50), // Similar a tu color de bienvenida
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Intenta cargar la imagen desde assets
            // Asegúrate de tener 'images/logo_bienvenida.png' en tu carpeta 'assets'
            // y declarado en pubspec.yaml
            // Image.asset('assets/images/logo_bienvenida.png', width: 200, height: 150), // Descomenta y ajusta
            Icon(Icons.store, size: 100, color: Colors.white), // Placeholder Icon
            SizedBox(height: 30),
            Text(
              'EmprendeApp',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Sistema de Gestión para Emprendedores',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3498db), // Color del botón
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _navigateToHome,
              child: Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}