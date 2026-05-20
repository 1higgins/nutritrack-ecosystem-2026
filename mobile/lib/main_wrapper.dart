import 'package:flutter/material.dart';
import 'screens/monitor_screen.dart';
import 'screens/analytics_screen.dart';

class MainWrapper extends StatefulWidget {
  final String token;
  final String role;
  final String userName;

  const MainWrapper({
    super.key,
    required this.token,
    required this.role,
    required this.userName,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 🌟 SE LIMPIÓ LA LISTA: Ahora solo existen las dos pantallas operativas principales
    final List<Widget> screens = [
      MonitorScreen(
        token: widget.token,
        role: widget.role,
        userName: widget.userName,
      ),
      AnalyticsScreen(
        token: widget.token,
        role: widget.role,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 🌟 SOLUCIÓN: Quitamos los NavItems de Alertas y Ajustes
            // Ahora el espacio se reparte de forma limpia y holgada entre estos dos.
            _buildPNGNavItem(0, "assets/icons/Inventario.png", "Inventario"),
            _buildPNGNavItem(1, "assets/icons/Estadisticas.png", "Recursos"),
          ],
        ),
      ),
    );
  }

  // Tu constructor de items optimizado mediante capas de expansión (Efecto Outline)
  Widget _buildPNGNavItem(int index, String assetPath, String label) {
    final bool isActive = _currentIndex == index;
    final Color activeColor = const Color.fromARGB(255, 0, 89, 255);
    final Color inactiveColor = const Color(0xFF94A3B8);
    final Color currentColor = isActive ? activeColor : inactiveColor;

    const double thickness = 0.5;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Capas de expansión en Cruz
              Transform.translate(
                  offset: const Offset(thickness, 0),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),
              Transform.translate(
                  offset: const Offset(-thickness, 0),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),
              Transform.translate(
                  offset: const Offset(0, thickness),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),
              Transform.translate(
                  offset: const Offset(0, -thickness),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),

              // Capas de expansión en Diagonal
              Transform.translate(
                  offset: const Offset(thickness, thickness),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),
              Transform.translate(
                  offset: const Offset(-thickness, -thickness),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),
              Transform.translate(
                  offset: const Offset(thickness, -thickness),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),
              Transform.translate(
                  offset: const Offset(-thickness, thickness),
                  child: Image.asset(assetPath,
                      width: 22.6,
                      height: 22.6,
                      color: currentColor.withOpacity(0.35))),

              // Icono Original
              Image.asset(
                assetPath,
                width: 22.6,
                height: 22.6,
                color: currentColor,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              color: currentColor,
            ),
          ),
        ],
      ),
    );
  }
}
