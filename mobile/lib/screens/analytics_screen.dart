import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'crearLotes.dart';
import 'vinculacion_screen.dart';
import 'entregarLotes.dart';
import 'crearUsuarios.dart';

class AnalyticsScreen extends StatefulWidget {
  final String token;
  final String? role;

  const AnalyticsScreen({
    super.key,
    required this.token,
    this.role,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================================================
              // ENCABEZADO
              // ==========================================================================

              const SizedBox(height: 7),

              Padding(
                padding: const EdgeInsets.only(left: 11.0),
                child: Text(
                  "Recursos operativos",
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 11.0),
                child: Text(
                  "Gestión de creación y accesos",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================================================

              // ==========================================================================
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 🌟 SOLUCIÓN: Calculamos la proporción ideal basada en la altura disponible real
                    final double exactWidth = (constraints.maxWidth - 16) / 2;
                    final double exactHeight = constraints.maxHeight / 2 - 130;
                    final double dynamicAspectRatio = exactWidth / exactHeight;

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      physics:
                          const NeverScrollableScrollPhysics(), // Evita scroll innecesario
                      childAspectRatio:
                          dynamicAspectRatio, // 🌟 Aplica la proporción perfecta
                      children: [
                        _buildOperationalBlock(
                          title: "Creación de lotes",
                          subtitle: "Despacha nuevas cargas",
                          icon: Icons.add_box_rounded,
                          primaryColor: const Color.fromARGB(255, 81, 148, 255),
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
                        _buildOperationalBlock(
                          title: "Vinculación de lotes",
                          subtitle: "Asignar ruta de transporte",
                          icon: Icons.local_shipping_rounded,
                          primaryColor: const Color.fromARGB(255, 21, 219, 77),
                          onTap: () async {
                            final bool? resultadoExito = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VinculacionScreen(token: widget.token),
                              ),
                            );

                            if (resultadoExito == true && context.mounted) {
                              // 🟢 Cambiado a context.mounted
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Custodia enlazada con éxito. Monitoreo térmico activo.",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: const Color(
                                      0xFF10B981), // Tu verde de éxito intacto
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        _buildOperationalBlock(
                          title: "Entrega de lotes",
                          subtitle: "Cierre formal de custodia",
                          icon: Icons.domain_verification_rounded,
                          primaryColor: const Color(0xFFF59E0B),
                          onTap: () async {
                            final bool? resultadoEntrega = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EntregaLotesScreen(token: widget.token),
                              ),
                            );

                            if (resultadoEntrega == true && context.mounted) {
                              // 🟢 Cambiado a context.mounted
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Ciclo de custodia cerrado. Lote marcado como ENTREGADO.",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  backgroundColor: const Color(0xFFF59E0B),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                        _buildOperationalBlock(
                          title: "Creación de usuarios",
                          subtitle: "Operadores (registro y roles)",
                          icon: Icons.person_add_alt_1_rounded,
                          primaryColor: const Color(0xFF6366F1),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // DISK CONSTRUCTOR (TEXTOS REPOSICIONADOS DINÁMICAMENTE)
  // ==========================================================================
  Widget _buildOperationalBlock({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withAlpha((0.03 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 32,
              ),
            ),
            // El Spacer o Padding inferior maneja el balance cuando la tarjeta crece verticalmente
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment
                    .end, // Lleva los textos abajo del bloque asignado
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                      height: 1.3,
                    ),
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
