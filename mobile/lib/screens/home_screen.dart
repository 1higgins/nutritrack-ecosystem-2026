import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'registro_screen.dart';
import 'inventario_screen.dart';
import 'temperatura_screen.dart';

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final String username;
=======
import 'package:flutter/services.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'entregarLotes_screen.dart';
import 'crearLotes_screen.dart';
import 'inventarioLotes.dart';
import 'crearUsuarios_screen.dart';
import 'vincularEntrega_screen.dart';

class HomeScreen extends StatefulWidget {
>>>>>>> Stashed changes
  final String token;
  const HomeScreen({super.key, required this.username, required this.token});

  static const Color appleBlue = Color(0xFF007AFF);
  static const Color bgColor = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color titleColor = Color(0xFF1C1C1E);

  static const _chips = [
    _ChipData(
      icon: Icons.thermostat_rounded,
      label: 'Temperatura',
      iconColor: Color(0xFFFF453A),
    ),
    _ChipData(
      icon: Icons.inventory_2_rounded,
      label: 'Lotes',
      iconColor: Color(0xFFFF9F0A),
    ),
    _ChipData(
      icon: Icons.store_rounded,
      label: 'Inventario',
      iconColor: Color(0xFF007AFF),
    ),
    _ChipData(
      icon: Icons.bar_chart_rounded,
      label: 'Reportes',
      iconColor: Color(0xFFBF5AF2),
    ),
  ];

<<<<<<< Updated upstream
  static const _cards = [
    _CardData(
      imagePlaceholderColor: Color(0xFFFFEEED),
      icon: Icons.thermostat_rounded,
      iconColor: Color(0xFFFF453A),
      title: 'Temperatura',
      subtitle: 'Monitoreo en tiempo real',
      destination: _Dest.temperatura,
    ),
    _CardData(
      imagePlaceholderColor: Color(0xFFFFF4E5),
      icon: Icons.inventory_2_rounded,
      iconColor: Color(0xFFFF9F0A),
      title: 'Registrar Lotes',
      subtitle: 'Agrega nuevos lotes',
      destination: _Dest.lotes,
    ),
    _CardData(
      imagePlaceholderColor: Color(0xFFE5F1FF),
      icon: Icons.store_rounded,
      iconColor: Color(0xFF007AFF),
      title: 'Inventario',
      subtitle: 'Gestiona tu stock',
      destination: _Dest.inventario,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hola de nuevo,',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: labelGray,
                                  letterSpacing: -0.3,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.4,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          offset: const Offset(0, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (value) {
                            if (value == 'logout') {
                              // logica para cerrar sesión, como limpiar token y navegar a login
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 20,
=======
class _HomeScreenState extends State<HomeScreen> {
  // Paleta de colores Premium basados en el diseño original
  static const Color bgColor = Color(0xFFF4F6F9); // Gris azulado ultra claro
  static const Color textMain =
      Color(0xFF0F172A); // Slate oscuro para jerarquía principal
  static const Color textSecondary =
      Color(0xFF64748B); // Slate medio para subtítulos

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
                const Text(
                  "¿Seguro que deseas cerrar sesión?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Tendrás que volver a ingresar tus credenciales para acceder al ecosistema de Nutritrack.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                    letterSpacing: -0.15,
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
                    child: const Text(
                      "Cerrar sesión",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.25,
                        color: Color(
                            0xFFEF4444), // Rojo corporativo exacto de la captura
                      ),
                    ),
                  ),
                ),

                //Línea Divisoria
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                  child: Divider(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
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
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.25,
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
                                    fontSize: 15,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentUserName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: textMain,
                                    letterSpacing: -1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayRole,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.3,
                                    color: textSecondary,
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
>>>>>>> Stashed changes
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Cerrar sesión',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          icon: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appleBlue.withOpacity(0.12),
                            ),
                            child: Center(
                              child: Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: appleBlue,
                                ),
                              ),
                            ),
                          ),
<<<<<<< Updated upstream
                        ),
                      ],
                    ),
=======
                        ],
                      ),
                    );
                  },
                ),
              ),

              //CÁPSULAS HORIZONTALES FIJAS
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

              // accesos rapidos
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 14, 24, 22),
                child: Text(
                  "Accesos rápidos",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textMain,
                    letterSpacing: -0.8,
>>>>>>> Stashed changes
                  ),
                  const SizedBox(height: 24),

                  // ── Scrollable chips ─────────────────────────────────
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _QuickChip(data: _chips[i]),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Section label ────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Accesos rápidos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── Animated cards list ──────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    i == _cards.length - 1 ? 24 : 14,
                  ),
                  child: _AnimatedCard(index: i, data: _cards[i], token: token),
                ),
                childCount: _cards.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated wrapper ─────────────────────────────────────────────────────────
class _AnimatedCard extends StatefulWidget {
  final int index;
  final _CardData data;
  final String token;
  const _AnimatedCard({
    required this.index,
    required this.data,
    required this.token,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // stagger each card by 80ms
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _DashCard(data: widget.data, token: widget.token),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────
class _ChipData {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _ChipData({
    required this.icon,
    required this.label,
    required this.iconColor,
  });
}

class _QuickChip extends StatelessWidget {
  final _ChipData data;
  const _QuickChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
<<<<<<< Updated upstream
          color: HomeScreen.cardColor,
          borderRadius: BorderRadius.circular(20),
=======
          // Fondo blanco limpio sin bordes
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // Sombra sutil para despegar el botón del fondo claro
>>>>>>> Stashed changes
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 16, color: data.iconColor),
            const SizedBox(width: 7),
            Text(
<<<<<<< Updated upstream
              data.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: HomeScreen.titleColor,
=======
              label,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w400,
                fontSize: 13,
                letterSpacing: -0.25,
>>>>>>> Stashed changes
              ),
            ),
          ],
        ),
      ),
    );
  }
}

<<<<<<< Updated upstream
// ─── Card data & dest ─────────────────────────────────────────────────────────
enum _Dest { temperatura, lotes, inventario }

class _CardData {
  final Color imagePlaceholderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final _Dest destination;
  const _CardData({
    required this.imagePlaceholderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.destination,
  });
}

// ─── Dashboard card (full width) ─────────────────────────────────────────────
class _DashCard extends StatelessWidget {
  final _CardData data;
  final String token;
  const _DashCard({required this.data, required this.token});

  void _navigate(BuildContext context) {
    Widget page;
    switch (data.destination) {
      case _Dest.temperatura:
        page = const TemperaturaPage();
        break;
      case _Dest.lotes:
        page = LotesPage(token: token);
        break;
      case _Dest.inventario:
        page = InventarioPage(token: token);
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: HomeScreen.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area — full width, taller now that card is wide
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
=======
  // Widget Constructor: Tarjetas de Acción del Cuerpo Principal
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
        borderRadius: BorderRadius.circular(30),
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
          onTap: onTap, //Se ejecuta la función al presionar
          borderRadius: BorderRadius.circular(24),
          splashColor: accentColor.withValues(alpha: 0.05),
          highlightColor: accentColor.withValues(alpha: 0.02),
          child: Column(
            children: [
              Container(
                height: 130,
>>>>>>> Stashed changes
                width: double.infinity,
                height: 150,
                color: data.imagePlaceholderColor,
                // Replace with: Image.asset('assets/images/xxx.png', fit: BoxFit.cover)
                child: Center(
                  child: Icon(
                    data.icon,
                    size: 64,
                    color: data.iconColor.withOpacity(0.22),
                  ),
                ),
              ),
            ),

            // Bottom: icon + text + chevron
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: data.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
<<<<<<< Updated upstream
                    child: Icon(data.icon, color: data.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: HomeScreen.titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          data.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HomeScreen.labelGray,
                            letterSpacing: -0.2,
=======
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
                              letterSpacing: -0.5,
                              color: textMain,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                                letterSpacing: -0.2),
>>>>>>> Stashed changes
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: HomeScreen.labelGray.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
