import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:mobile/screens/login_screen.dart';
=======
import 'screens/login_screen.dart';
>>>>>>> Stashed changes

void main() {
  runApp(const Nutritrack());
}

class Nutritrack extends StatelessWidget {
  const Nutritrack({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
=======
    return MaterialApp(
      title: 'NutriTrack Enterprise Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // Tipografía global profesional

        textTheme: const TextTheme(),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
          primary: const Color(0xFF1E293B),
          secondary: const Color(0xFF2E6CA4),
        ),

        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const LoginScreen(),
    );
>>>>>>> Stashed changes
  }
}
