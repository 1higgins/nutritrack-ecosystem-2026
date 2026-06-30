import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/screens/entregarLotes.dart';
import 'package:mobile_app/screens/crearUsuarios.dart';

import 'login_screen.dart';
import '../services/auth_service.dart';
import 'crearLotes.dart';
import 'Inventario_screen.dart';
import 'vinculacion_screen.dart';

// Encapsula y centraliza los permisos basándose en el rol limpio
class AppPermissions {
  final String role;

  AppPermissions(String rawRole) : role = rawRole.trim().toLowerCase();

  bool get isAdmin => role == 'administrador' || role == 'admin';
  bool get isOperario => role == 'operario' || role == 'opa';
  bool get isTransportista => role == 'transportista' || role == 'opt';

  bool get canManageLotes => isAdmin || isOperario;
  bool get canLinkLotes => isTransportista;
  bool get canManageUsers => isAdmin;

  String get displayRole {
    if (isAdmin) return "Administrador";
    if (isOperario) return "Operario";
    if (isTransportista) return "Transportista";
    return role;
  }
}

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
  static const Color bgColor = Color(0xFFF2F2F7);
  static const Color textMain = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);

  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 25, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 34),
                const Text(
                  "¿Seguro que deseas cerrar sesión?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textMain,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Tendrás que volver a ingresar tus credenciales para acceder al ecosistema de NutriTrack.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 36),
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
                    child: const Text(
                      "Cerrar sesión",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Divider(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                    thickness: 1,
                  ),
                ),
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
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        letterSpacing: -0.2,
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
    final perms = AppPermissions(widget.role);
    final String currentUserName = widget.userName;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                const Text(
                                  "Hola de nuevo,",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 51, 53, 57),
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 0),
                                Text(
                                  currentUserName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 31,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  perms.displayRole,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromARGB(255, 51, 53, 57),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: topAvatar,
                            right: rightAvatar,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showLogoutBottomSheet(context),
                                customBorder: const CircleBorder(),
                                splashColor:
                                    Colors.white.withValues(alpha: 0.3),
                                highlightColor:
                                    Colors.white.withValues(alpha: 0.15),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
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
                    if (perms.canManageLotes) ...[
                      const SizedBox(width: 12),
                      _buildCategoryPill(
                        label: "Lotes",
                        icon: Icons.archive_rounded,
                        color: Colors.amber[600]!,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreacionLotesScreen(
                                token: widget.token,
                                role: widget.role,
                                userName: widget.userName,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (perms.canLinkLotes) ...[
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
                    if (perms.canManageUsers) ...[
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
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 22),
                child: Text(
                  "Accesos rápidos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
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
                    if (perms.canManageLotes) ...[
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
                              builder: (context) => CreacionLotesScreen(
                                token: widget.token,
                                role: '',
                                userName: '',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (perms.canLinkLotes) ...[
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
                    if (perms.canManageUsers) ...[
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.w500,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bannerColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: accentColor.withValues(alpha: 0.05),
          highlightColor: accentColor.withValues(alpha: 0.02),
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
                    color: accentColor.withValues(alpha: 0.8),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textMain,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color.fromARGB(255, 56, 56, 65),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: textSecondary.withValues(alpha: 0.6),
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
