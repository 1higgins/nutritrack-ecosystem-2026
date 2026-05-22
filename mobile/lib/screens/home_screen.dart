import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// 📌 IMPORTACIONES ADICIONALES REQUERIDAS PARA LA LÓGICA DE NEGOCIO
import 'login_screen.dart';
import '../services/auth_service.dart';
// 📌 IMPORTACIONES DE LAS PANTALLAS DE DESTINO
import 'entregados_screen.dart';
import 'creacion_lotes_screen.dart';
import 'monitor_screen.dart';
import 'usuarios_screen.dart';
import 'vinculacion_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final String role;
  final String userName;

  const HomeScreen({
    super.key,
    required this.token,
    required this.role,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Paleta de colores Premium basados en el diseño original
  static const Color bgColor = Color(0xFFF4F6F9); // Gris azulado ultra claro
  static const Color textMain =
      Color(0xFF0F172A); // Slate oscuro para jerarquía principal
  static const Color textSecondary =
      Color(0xFF64748B); // Slate medio para subtítulos

  /// 📌 MÉTODO PRIVADO: Muestra el panel inferior premium de confirmación de cierre de sesión
  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top:
                Radius.circular(32)), // Bordes ligeramente más curvos y premium
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 25, 24,
                32), // Equilibra el espacio blanco sin romper la simetría
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 📌 Indicador visual superior (Pill ploma integrada al techo)
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 36), // Distancia exacta hacia el icono

                // 📌 Icono premium circular fusionado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2), // Fondo rojo sutil
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444), // Rojo de alerta
                    size: 28,
                  ),
                ),
                const SizedBox(height: 34),

                // 📌 Textos del Diálogo fusionados en armonía
                Text(
                  "¿Seguro que deseas cerrar sesión?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Tendrás que volver a ingresar tus credenciales para acceder al ecosistema de NutriTrack.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                    height:
                        36), // Espacio de desahogo antes de las acciones de la captura

                // 📌 BOTÓN 1: Cerrar Sesión (Estilo interactivo central)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(bottomSheetContext);
                      final AuthService authService = AuthService();
                      await authService.logout();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      foregroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Cerrar sesión",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(
                            0xFFEF4444), // Rojo corporativo exacto de la captura
                      ),
                    ),
                  ),
                ),

                // 📌 Línea Divisoria Sutil de la captura
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Divider(
                    color: const Color(0xFFE2E8F0).withOpacity(0.6),
                    thickness: 1,
                  ),
                ),

                // 📌 BOTÓN 2: Cancelar (Estilo plano inferior de la captura)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "Cancelar",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color:
                            textSecondary, // Gris equilibrado para menor jerarquía
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE EXTRACCIÓN Y TRADUCCIÓN DE ROL ---
    String displayRole;

    // Convertimos a minúsculas el string largo que viene del login
    switch (widget.role.toLowerCase()) {
      case 'administrador':
      case 'admin':
        displayRole = "Administrador";
        break;
      case 'operario':
      case 'opa':
        displayRole = "Operario";
        break;
      case 'transportista':
      case 'opt':
        displayRole = "Transportista";
        break;
      default:
        displayRole = widget.role;
    }

    final String currentUserName = widget.userName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 1. ENCABEZADO FIJO DE TUS TEXTOS (Inmune al scroll o estiramientos con el dedo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Builder(
                  builder: (context) {
                    const double topTexts = 20.0;
                    const double topAvatar = 45.0;
                    const double rightAvatar = 5.0;

                    return SizedBox(
                      height: 123,
                      child: Stack(
                        children: [
                          Positioned(
                            top: topTexts,
                            left: 0,
                            right: 70,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hola de nuevo,",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUserName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 31,
                                    fontWeight: FontWeight.w600,
                                    color: textMain,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayRole,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 📌 AVATAR TRANSFORMATO A BOTÓN INTERACTIVO PROFESIONAL (Preserva las coordenadas exactas)
                          Positioned(
                            top: topAvatar,
                            right: rightAvatar,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showLogoutBottomSheet(context),
                                customBorder: const CircleBorder(),
                                splashColor: Colors.white.withOpacity(0.3),
                                highlightColor: Colors.white.withOpacity(0.15),
                                child: Container(
                                  height: 48,
                                  width: 48,
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 69, 162, 255),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // 📌 2. CÁPSULAS HORIZONTALES FIJAS (Tampoco se desplazan verticalmente)
              // 📌 2. CÁPSULAS HORIZONTALES FIJAS (Filtradas por Rol dinámicamente)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    // CÁPSULA: Inventario (Visible para TODOS: admin, opt, opa)
                    _buildCategoryPill(
                      label: "Inventario",
                      icon: Icons.inventory,
                      color: const Color.fromARGB(255, 68, 174, 255),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MonitorScreen(
                              token: widget.token,
                              role: widget.role,
                              userName: widget.userName,
                            ),
                          ),
                        );
                      },
                    ),

                    // CÁPSULA: Entregas (Visible para TODOS: admin, opt, opa)
                    const SizedBox(width: 12),
                    _buildCategoryPill(
                      label: "Entregas",
                      icon: Icons.inventory_rounded,
                      color: const Color.fromARGB(255, 43, 235, 72),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EntregaLotesScreen(token: widget.token),
                          ),
                        );
                      },
                    ),

                    // CÁPSULA: Lotes / Registrar Lotes (Visible para ADMIN y OPA)
                    if (widget.role.toLowerCase() == 'administrador' ||
                        widget.role.toLowerCase() == 'operario' ||
                        widget.role.toLowerCase() == 'admin' ||
                        widget.role.toLowerCase() == 'opa') ...[
                      const SizedBox(width: 12),
                      _buildCategoryPill(
                        label: "Lotes",
                        icon: Icons.archive_rounded,
                        color: Colors.amber[600]!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CreacionLotesScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],

                    // CÁPSULA: Conexión / Vincular Lotes (Visible SOLO para OPT)
                    if (widget.role.toLowerCase() == 'transportista' ||
                        widget.role.toLowerCase() == 'opt') ...[
                      const SizedBox(width: 12),
                      _buildCategoryPill(
                        label: "Conexión",
                        icon: Icons.local_shipping_rounded,
                        color: const Color.fromARGB(255, 30, 197, 183),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VinculacionScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],

                    // CÁPSULA: Usuarios / Crear Usuarios (Visible SOLO para ADMIN)
                    if (widget.role.toLowerCase() == 'administrador' ||
                        widget.role.toLowerCase() == 'admin') ...[
                      const SizedBox(width: 12),
                      _buildCategoryPill(
                        label: "Usuarios",
                        icon: Icons.person_add_alt_1_rounded,
                        color: const Color.fromARGB(255, 93, 95, 239),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UsuariosScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // 📌 TÍTULO SECCIÓN ACCESOS RÁPIDOS (Fijo)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
                child: Text(
                  "Accesos rápidos",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              // 📌 3. ÁREA DE SCROLL EXCLUSIVA PARA LAS TARJETAS GRANDES
              // 📌 3. ÁREA DE SCROLL EXCLUSIVA PARA LAS TARJETAS GRANDES
              // 📌 3. ÁREA DE SCROLL EXCLUSIVA PARA LAS TARJETAS GRANDES
              // 📌 3. ÁREA DE SCROLL EXCLUSIVA PARA LAS TARJETAS GRANDES (Filtradas por Rol)
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    // 1. Inventario Global (Visible para TODOS: admin, opt, opa)
                    _buildFeatureCard(
                      title: "Inventario Global",
                      subtitle: "Estado de productos refrigerados",
                      icon: Icons.inventory,
                      accentColor: const Color.fromARGB(255, 68, 174, 255),
                      bannerColor: const Color(0xFFEBF3FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MonitorScreen(
                              token: widget.token,
                              role: widget.role,
                              userName: widget.userName,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Confirmar Entrega (Visible para TODOS: admin, opt, opa)
                    _buildFeatureCard(
                      title: "Confirmar Entrega",
                      subtitle: "Registrar lotes entregados",
                      icon: Icons.inventory_rounded,
                      accentColor: const Color.fromARGB(255, 43, 235, 72),
                      bannerColor: const Color(0xFFE8F8EE),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EntregaLotesScreen(token: widget.token),
                          ),
                        );
                      },
                    ),

                    // 3. Registrar Lotes (Visible para ADMIN y OPA)
                    if (widget.role.toLowerCase() == 'administrador' ||
                        widget.role.toLowerCase() == 'operario' ||
                        widget.role.toLowerCase() == 'admin' ||
                        widget.role.toLowerCase() == 'opa') ...[
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        title: "Registrar Lotes",
                        subtitle: "Agrega nuevos lotes",
                        icon: Icons.archive_rounded,
                        accentColor: const Color(0xFFFFA000),
                        bannerColor: const Color(0xFFFFF7E6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CreacionLotesScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],

                    // 4. Conexión a Lotes / Vincular (Visible SOLO para OPT)
                    if (widget.role.toLowerCase() == 'transportista' ||
                        widget.role.toLowerCase() == 'opt') ...[
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        title: "Conexión a Lotes",
                        subtitle: "Vincular con los cargamentos del inventario",
                        icon: Icons.local_shipping_rounded,
                        accentColor: const Color.fromARGB(255, 30, 197, 183),
                        bannerColor: const Color(0xFFE6F7F6),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VinculacionScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],

                    // 5. Creación de Usuarios (Visible SOLO para ADMIN)
                    if (widget.role.toLowerCase() == 'administrador' ||
                        widget.role.toLowerCase() == 'admin') ...[
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        title: "Creación de Usuarios",
                        subtitle: "Gestionar accesos y perfiles del ecosistema",
                        icon: Icons.person_add_alt_1_rounded,
                        accentColor: const Color(0xFF5D5FEF),
                        bannerColor: const Color(0xFFEEEEFF),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UsuariosScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 32), // Margen de desahogo final
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Constructor: Píldoras superiores
  // Widget Constructor: Píldoras superiores (Diseño Minimalista Original Restaurado con Clic)
  Widget _buildCategoryPill({
    required String label,
    required IconData icon,
    required Color color, // Se usa solo para el ícono
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          // Fondo blanco limpio sin bordes
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Sombra sutil para despegar el botón del fondo claro
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. El ícono mantiene su color correspondiente (verde, azul, etc.)
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            // 2. El texto ahora es negro elegante (Slate oscuro)
            Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B), // Letra negra/oscura limpia
                fontWeight: FontWeight.w600, // Grosor balanceado y estético
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Constructor: Tarjetas de Acción del Cuerpo Principal
  // Widget Constructor Actualizado: Tarjetas de Acción con clic interactivo
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bannerColor,
    required VoidCallback onTap, // 👈 1. Agregamos el callback del clic
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        // 👈 2. Agregamos Material e InkWell para el efecto visual de presión
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap, // 👈 3. Se ejecuta la función al presionar
          borderRadius: BorderRadius.circular(24),
          splashColor: accentColor.withOpacity(0.05),
          highlightColor: accentColor.withOpacity(0.02),
          child: Column(
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bannerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 56,
                    color: accentColor.withOpacity(0.8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bannerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: textSecondary.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
