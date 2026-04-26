import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'screens/login_screen.dart';

void main() {
  // Estándar industrial: Garantizar inicialización de Flutter

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const NutriTrackApp());
}

class NutriTrackApp extends StatelessWidget {
  const NutriTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriTrack Enterprise Mobile',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        // Tipografía global profesional

        textTheme: GoogleFonts.poppinsTextTheme(),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          primary: const Color(0xFF1E293B),
          secondary: const Color(0xFF2E6CA4),
        ),

        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),

      // El flujo siempre inicia en LoginScreen por seguridad JWT

      home: const LoginScreen(),
    );
  }
}
