import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'screens/monitor_screen.dart';
import 'screens/analytics_screen.dart';

class MainWrapper extends StatefulWidget {
  final String token;
  final String role; // <--- Declarada correctamente

  // CORRECCIÓN DEL CONSTRUCTOR:
  const MainWrapper(
      {super.key,
      required this.token,
      required this.role // <--- Añadida como requerida
      });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  // Lista de pantallas inyectadas con el token de sesión

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      // 1. Monitor: Recibe Token y Rol (Para el botón de Google Drive)
      MonitorScreen(token: widget.token, role: widget.role),

      // 2. Analytics: Recibe Token (Para sus peticiones HTTP)
      AnalyticsScreen(token: widget.token),

      // 3. Historial (Placeholder funcional)
      const _PlaceholderScreen(
        title: "HISTORIAL DE ALERTAS",
        icon: Icons.history_edu_rounded,
      ),

      // 4. Soporte (Placeholder funcional)
      const _PlaceholderScreen(
        title: "SOPORTE TÉCNICO",
        icon: Icons.support_agent_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial para el efecto visual del CurvedNavigationBar

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),

      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,

        index: 0,

        height: 65.0,

        items: const <Widget>[
          Icon(Icons.dashboard_rounded, size: 28, color: Colors.white),
          Icon(Icons.bar_chart_rounded, size: 28, color: Colors.white),
          Icon(
            Icons.notifications_active_rounded,
            size: 28,
            color: Colors.white,
          ),
          Icon(Icons.settings_suggest_rounded, size: 28, color: Colors.white),
        ],

        color: const Color(0xFF1E293B), // Azul Industrial profundo

        buttonBackgroundColor: const Color(0xFF2E6CA4), // Azul NutriTrack

        backgroundColor: Colors.transparent,

        animationCurve: Curves.easeInOutCubic,

        animationDuration: const Duration(milliseconds: 500),

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Módulo en fase de integración operativa",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
