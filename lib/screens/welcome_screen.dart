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
      backgroundColor: Colors.white, // Fondo blanco limpio
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Carga la imagen desde assets
            SizedBox(
              width: 220,
              height: 220,
              child: Image.asset(
                'assets/images/logo_bienvenida.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.store, size: 120, color: Color(0xFF1976D2));
                },
              ),
            ),
            SizedBox(height: 60),
            Text(
              'CREADA PARA TI,\nDISEÑADA PARA TU ÉXITO',
              style: TextStyle(
                fontSize: 22,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 80),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2), // Azul más profesional
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _navigateToHome,
                child: Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}