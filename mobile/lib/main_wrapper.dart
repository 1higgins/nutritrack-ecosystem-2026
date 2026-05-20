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
    // 👇 Mudar la lista aquí reconstruye las pantallas dinámicamente con datos reales sin congelar nulos
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
      const Center(child: Text("Centro de Alertas")),
      const Center(child: Text("Ajustes de Cuenta")),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 68, // Mantenemos tu medida
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
            // Todos los items ahora usan tus PNGs personalizados
            _buildPNGNavItem(0, "assets/icons/Inventario.png", "Inventario"),
            _buildPNGNavItem(1, "assets/icons/Estadisticas.png", "Recursos"),
            _buildPNGNavItem(2, "assets/icons/notificaciones.png", "Alertas"),
            _buildPNGNavItem(3, "assets/icons/ajustamiento.png", "Ajustes"),
          ],
        ),
      ),
    );
  }

  // Lógica unificada para todos tus PNGs sin la barrita azul
  Widget _buildPNGNavItem(int index, String assetPath, String label) {
    final bool isActive = _currentIndex == index;
    final Color activeColor = const Color.fromARGB(255, 0, 89, 255);
    final Color inactiveColor = const Color(0xFF94A3B8);
    final Color currentColor = isActive ? activeColor : inactiveColor;

    // CONTROL DE GROSOR: Ajusta este número (0.5 es bastante fuerte)
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
              // --- CAPAS DE EXPANSIÓN EN CRUZ ---
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

              // --- CAPAS DE EXPANSIÓN EN DIAGONAL ---
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

              // --- ICONO ORIGINAL (Centro) ---
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
              fontSize: 9.5, // <--- Este es el tamaño que pediste mantener
              fontWeight: isActive
                  ? FontWeight.w900
                  : FontWeight.w700, // <--- Volvemos al peso original
              color: currentColor,
            ),
          ),
        ],
      ),
    );
  }
}
