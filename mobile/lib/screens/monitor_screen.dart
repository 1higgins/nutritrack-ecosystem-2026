import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../models/lote_model.dart';

import '../services/lote_service.dart';

import 'lote_detail_screen.dart';

class MonitorScreen extends StatefulWidget {
  final String token;

  final String role;

  final String userName;

  const MonitorScreen({
    super.key,
    required this.token,
    required this.role,
    required this.userName,
  });

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen>
    with TickerProviderStateMixin {
  final LoteService _loteService = LoteService();

  late Future<List<Lote>> _futureLotes;

  String _selectedCategory = "Todos";

  final _searchController = TextEditingController();

  // --- CONTROLADORES INDUSTRIALES ---

  final _codigoController = TextEditingController();

  final _productoController = TextEditingController();

  final _tempMinController = TextEditingController();

  final _tempMaxController = TextEditingController();

  final _passwordLoteController = TextEditingController();

  final _nombreOpaController = TextEditingController();

  // --- NUEVAS VARIABLES DE ESTADO DE AUDITORÍA ---

  String _filterRangoFecha =
      "24h"; // Inicia por defecto en 24h para evitar saturación

  String _filterUsername = ""; // Almacena el OPA exacto buscado por el Admin

  bool _mostrarBotonQR = false;

  // Estado de carga para botones

  bool _isLoadingAction = false;

  String _currentFormType = ""; // Almacena: 'crear', 'vincular' o 'entregar'

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  /// Carga de datos optimizada con persistencia de filtros para el Pull-to-Refresh

  void _loadData() {
    setState(() {
      _futureLotes = _loteService.fetchLotes(
        widget.token,
        username:
            _filterUsername.trim().isEmpty ? null : _filterUsername.trim(),
        rangoFecha: _filterRangoFecha,
      );
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();

    _productoController.dispose();

    _tempMinController.dispose();

    _tempMaxController.dispose();

    _passwordLoteController.dispose();

    _nombreOpaController.dispose();

    _searchController.dispose();

    super.dispose();
  }

  // --- MÉTODOS DE LÓGICA ---

  String? _validarFormularioLote() {
    if (_codigoController.text.trim().isEmpty) {
      return "El Código/Nombre del lote es obligatorio";
    }

    if (_passwordLoteController.text.trim().length < 4) {
      return "La contraseña de seguridad debe tener al menos 4 caracteres";
    }

    switch (_currentFormType) {
      case "crear":
        if (_productoController.text.trim().isEmpty) {
          return "Debe especificar el producto para el registro";
        }

        return _validarRangosTermicos();

      case "vincular":
        return null;

      case "entregar":
        if (_nombreOpaController.text.trim().isEmpty) {
          return "El nombre del OPA emisor es obligatorio para la entrega";
        }

        return null;

      default:
        return "Error de contexto: Acción no identificada";
    }
  }

  String? _validarRangosTermicos() {
    final double? min =
        double.tryParse(_tempMinController.text.replaceAll(',', '.'));

    final double? max =
        double.tryParse(_tempMaxController.text.replaceAll(',', '.'));

    if (min == null || max == null) {
      return "Las temperaturas deben ser números";
    }

    if (min > max) {
      return "Mínimo no puede ser mayor al máximo";
    }

    if (min == max) {
      return "Debe existir un rango operativo (Min ≠ Max)";
    }

    if (min < -50.0 || max > 100.0) {
      return "Rango fuera de límites del sensor (-50°C a 100°C)";
    }

    if (_passwordLoteController.text.length < 4) {
      return "Password debe tener min. 4 caracteres";
    }

    return null;
  }

  void _clearControllers() {
    _codigoController.clear();

    _productoController.clear();

    _tempMinController.clear();

    _tempMaxController.clear();

    _passwordLoteController.clear();

    _nombreOpaController.clear();
  }

  // ==========================================================================

  // LÓGICA DE FILTRADO COMBINADO LOCAL (Buscador + Chips)

  // Operando sobre el universo ya pre-filtrado por el Servidor

  // ==========================================================================

  List<Lote> _getFilteredLotes(List<Lote> allLotes) {
    return allLotes.where((lote) {
      final query = _searchController.text.toLowerCase();

      final matchesSearch = lote.codigoLote.toLowerCase().contains(query) ||
          lote.producto.toLowerCase().contains(query);

      if (!matchesSearch) return false;

      switch (_selectedCategory) {
        case "Entregados":
          return lote.entregado == true;

        case "Buenos":
          return !lote.entregado &&
              lote.estadoActual.toUpperCase().contains('OPTIMO');

        case "Alerta":
          return !lote.entregado &&
              lote.estadoActual.toUpperCase().contains('ALERTA');

        case "Critico":
          return !lote.entregado &&
              lote.estadoActual.toUpperCase().contains('CRITICO');

        case "Todos":
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 🟢 MODIFICACIÓN AQUÍ: Si es true se dibuja, si es false se oculta (null)

      floatingActionButton: !_mostrarBotonQR
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 88, right: 2),
              child: GestureDetector(
                onTap: () {
                  if (widget.role == "OPA") {
                    _showFormModal(tipo: "crear");
                  } else {
                    _showActionMenu();
                  }
                },
                child: Container(
                  height: 85,
                  width: 85,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2374A6), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2374A6).withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),

      body: FutureBuilder<List<Lote>>(
        future: _futureLotes,
        builder: (context, snapshot) {
          final List<Lote>? lotesActuales = snapshot.data;

          return Column(
            children: [
              _buildSystemStatsHeader(lotesActuales),

              // Pasamos el snapshot para validar la existencia de lotes mínimos antes de mostrar el botón

              _buildSearchAndFilterSection(lotesActuales),

              const SizedBox(height: 10),

              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF3B82F6),
                  onRefresh: () async => _loadData(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        sliver: _buildSliverContent(snapshot),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSystemStatsHeader(List<Lote>? lotes) {
    if (lotes == null) {
      return _buildHeaderLayout(
          total: "...", buenos: "...", alerta: "...", critico: "...");
    }

    final List<Lote> lotesActivos = lotes.where((l) => !l.entregado).toList();

    int buenos = 0;

    int alerta = 0;

    int critico = 0;

    for (var lote in lotesActivos) {
      final String estado = lote.estadoActual.toUpperCase();

      if (estado.contains('OPTIMO')) {
        buenos++;
      } else if (estado.contains('ALERTA')) {
        alerta++;
      } else if (estado.contains('CRITICO')) {
        critico++;
      }
    }

    return _buildHeaderLayout(
      total: lotesActivos.length.toString(),
      buenos: buenos.toString(),
      alerta: alerta.toString(),
      critico: critico.toString(),
    );
  }

  Widget _buildHeaderLayout({
    required String total,
    required String buenos,
    required String alerta,
    required String critico,
  }) {
    return Container(
      width: double.infinity,

      // Añadimos un pequeño padding superior extra para respetar la barra de estado del dispositivo

      padding: EdgeInsets.fromLTRB(
          22, MediaQuery.of(context).padding.top + 16, 22, 14.5),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row para alinear el título y tu nuevo botón en extremos opuestos

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Inventario",
                style: GoogleFonts.inter(
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B)),
              ),

              // 🏠 BOTÓN HOME (Estilo Turquesa con fondo Celeste Transparente)

              GestureDetector(
                onTap: () {
                  // Regresa de forma limpia a la pantalla anterior (home_screen.dart)

                  Navigator.pop(context);
                },
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    // Fondo celeste muy suave y transparente

                    color: const Color(0xFFE0F2FE).withValues(alpha: 0.6),

                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.home_rounded, // Ícono de casa amigable

                    color: Color.fromARGB(
                        255, 79, 182, 255), // Color turquesa estilizado

                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5.5),

          Text(
            "Gestión de productos refrigerados",
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B)),
          ),

          const SizedBox(height: 19),

          Row(
            children: [
              _buildStatCard(total, "Total", const Color(0xFF64748B),
                  const Color(0xFFF8FAFC)),
              const SizedBox(width: 8),
              _buildStatCard(
                  buenos,
                  "Buenos",
                  const Color.fromARGB(255, 7, 206, 47),
                  const Color(0xFFECFDF5)),
              const SizedBox(width: 8),
              _buildStatCard(
                  alerta,
                  "Alerta",
                  const Color.fromARGB(255, 231, 151, 13),
                  const Color(0xFFFFFBEB)),
              const SizedBox(width: 8),
              _buildStatCard(
                  critico,
                  "Crítico",
                  const Color.fromARGB(255, 236, 6, 6),
                  const Color(0xFFFEF2F2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverContent(AsyncSnapshot<List<Lote>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverFillRemaining(
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 3, color: Color(0xFF3B82F6))),
      );
    }

    if (snapshot.hasError) {
      return SliverFillRemaining(
          child: _buildErrorState(snapshot.error.toString()));
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    final filteredList = _getFilteredLotes(snapshot.data!);

    if (filteredList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded,
                  size: 50, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              Text(
                "No se encontraron resultados",
                style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildIndustrialLoteCard(filteredList[index]),
        childCount: filteredList.length,
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndustrialLoteCard(Lote lote) {
    // 1. Normalización del estado y extracción analítica de propiedades cromáticas y de iconografía

    final String estadoStr = lote.estadoActual.toUpperCase();

    IconData statusIcon;

    Color statusColor;

    if (estadoStr.contains('CRITICO')) {
      statusIcon = Icons.error_rounded;

      statusColor = const Color(0xFFEF4444); // 🔴 Crítico (Rojo)
    } else if (estadoStr.contains('ALERTA')) {
      statusIcon = Icons.warning_rounded;

      statusColor = const Color(0xFFF59E0B); // 🟡 Alerta (Amarillo/Ámbar)
    } else if (estadoStr.contains('OPTIMO')) {
      statusIcon = Icons.inventory_2_rounded;

      statusColor = const Color.fromARGB(255, 14, 216, 51); // 🟢 Óptimo (Verde)
    } else {
      statusIcon = Icons.pending_actions_rounded;

      statusColor = const Color(0xFF0059FF); // 🔵 Esperando (Azul Industrial)
    }

    // Determinación del color del borde estructural perimetral

    final Color borderColor = estadoStr.contains('ESPERANDO')
        ? const Color(0xFF0059FF)
        : lote.colorEstado;

    final String transportistaAsignado =
        (lote.custodioUsername != null && lote.custodioUsername!.isNotEmpty)
            ? lote.custodioUsername!
            : "...";

    final String ultimaTemp = (lote.ultimaTemperatura != null)
        ? "${lote.ultimaTemperatura!.toStringAsFixed(1)}°C"
        : "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: borderColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LoteDetailScreen(token: widget.token, loteId: lote.id),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================================

              // ✨ SECCIÓN SUPERIOR: Banner Industrial de Estado + Badge Flotante (SIN BORDES)

              // ==================================================================

              Container(
                height: 120, // Altura optimizada para la jerarquía visual

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: statusColor.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                ),

                child: Stack(
                  children: [
                    // Icono de estado central perfectamente alineado

                    Center(
                      child: Icon(
                        statusIcon,
                        color: statusColor.withValues(alpha: 0.55),
                        size: 52,
                      ),
                    ),

                    // Badge posicionado en la esquina superior derecha

                    Positioned(
                      top: 14,

                      right: 14,

                      child: !estadoStr.contains('ESPERANDO')
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                // Se adapta dinámicamente al color del lote con opacidad sutil

                                color: statusColor.withValues(alpha: 0.1),

                                borderRadius: BorderRadius.circular(20),

                                // ❌ SE ELIMINÓ EL BORDE AQUÍ para un diseño más limpio
                              ),
                              child: Text(
                                lote.entregado ? "ENTREGADO" : "EN TRÁNSITO",
                                style: GoogleFonts.inter(
                                  color:
                                      statusColor, // Mismo color matriz del lote

                                  fontSize: 9,

                                  fontWeight: FontWeight.w700,

                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          : const SizedBox
                              .shrink(), // Oculto completamente en "Esperando"
                    ),
                  ],
                ),
              ),

              // ==================================================================

              // 📊 SECCIÓN INFERIOR: Métricas y Datos Técnicos

              // ==================================================================

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encebezado interno de la tarjeta: Identificadores técnicos

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildStatusIndicator(lote),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lote.codigoLote,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF0F172A),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMiniBadge(lote),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lote.producto.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Línea divisoria industrial con opacidad adaptativa

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                        height: 1,
                        thickness: 1,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // Matriz de Datos Técnicos (Límites, Temperatura y Custodio)

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna Izquierda: Umbrales térmicos configurados

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataRow(
                                icon: Icons.arrow_downward_rounded,
                                iconColor: const Color(0xFF3B82F6),
                                label: "Limite (Mín):",
                                value:
                                    "${lote.tempMinIdeal.toStringAsFixed(1)}°C",
                              ),
                              const SizedBox(height: 7),
                              _buildDataRow(
                                icon: Icons.arrow_upward_rounded,
                                iconColor: const Color(0xFFEF4444),
                                label: "Limite (Máx):",
                                value:
                                    "${lote.tempMaxIdeal.toStringAsFixed(1)}°C",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Columna Derecha: Estado de telemetría en tiempo real

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataRow(
                                icon: Icons.thermostat_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                label: "Temp:",
                                value: ultimaTemp,
                                highlight: true,
                              ),
                              const SizedBox(height: 7),
                              _buildDataRow(
                                icon: Icons.local_shipping_rounded,
                                iconColor:
                                    const Color.fromARGB(255, 82, 96, 114),
                                label: "Conductor:",
                                value: transportistaAsignado,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildDataRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor.withValues(alpha: 0.8)),
        const SizedBox(width: 4.5),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 11.7,
              fontWeight: FontWeight.w500,
              color: const Color.fromARGB(255, 84, 93, 106)),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  // ==========================================================================

  // 🔍 SECCIÓN DE BUSCADOR CON BOTÓN DE FILTROS INTEGRADO (SIMETRÍA INDUSTRIAL)

  // ==========================================================================

  // ==========================================================================

  // 🔍 SECCIÓN DE BUSCADOR CON BOTÓN DE FILTROS INTEGRADO (SIEMPRE VISIBLE)

  // ==========================================================================

  Widget _buildSearchAndFilterSection(List<Lote>? lotes) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 0),
      child: Column(
        children: [
          Row(
            children: [
              // El Buscador se expande para tomar el espacio disponible

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Focus(
                    onFocusChange: (hasFocus) => setState(() {}),
                    child: Builder(
                      builder: (context) {
                        final bool isFocused = Focus.of(context).hasFocus;

                        return TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: isFocused
                                ? ""
                                : "Buscar por codigo o producto...",
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8), fontSize: 14.5),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 40),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.search_rounded,
                                  color: Color(0xFF64748B), size: 20),
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 🟢 EL BOTÓN AHORA QUEDA LIBERADO DE CONDICIONES (SIEMPRE SE RENDERIZA)

              const SizedBox(width: 8),

              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: (_filterUsername.isNotEmpty ||
                            _filterRangoFecha != "24h")
                        ? const Color(0xFF0059FF).withValues(
                            alpha:
                                0.25) // Se ilumina en azul si hay filtros activos

                        : const Color(0xFFE2E8F0),
                    width: (_filterUsername.isNotEmpty ||
                            _filterRangoFecha != "24h")
                        ? 1.5
                        : 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: (_filterUsername.isNotEmpty ||
                            _filterRangoFecha != "24h")
                        ? const Color(0xFF0059FF)
                        : const Color(0xFF64748B),
                    size: 22,
                  ),

                  onPressed: () =>
                      _openAdvancedFilterModal(lotes), // Siempre se puede abrir
                ),
              ),
            ],
          ),

          const SizedBox(height: 6.5),

          // --- CATEGORÍAS (CHIPS) ---

          Row(
            children: [
              _buildFilterChip(
                  id: "Entregados",
                  child:
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                  isIcon: true),
              const SizedBox(width: 7),
              Expanded(child: _buildFilterChip(id: "Buenos", label: "Buenos")),
              const SizedBox(width: 7),
              Expanded(child: _buildFilterChip(id: "Alerta", label: "Alerta")),
              const SizedBox(width: 7),
              Expanded(
                  child: _buildFilterChip(id: "Critico", label: "Crítico")),
            ],
          ),
        ],
      ),
    );
  }

  void _openAdvancedFilterModal(List<Lote>? lotes) {
    // 1. Validamos el rol de forma segura (ignorando mayúsculas/minúsculas)
    final String rolUsuario = widget.role.toLowerCase();
    final bool esAdmin = rolUsuario == "admin";

    String tempRangoFecha = _filterRangoFecha;

    // Si no es admin, el filtro de username se limpia automáticamente por seguridad
    final TextEditingController tempUserController =
        TextEditingController(text: esAdmin ? _filterUsername : "");

    final List<Map<String, String>> opcionesTiempo = [
      {"id": "all", "label": "Todo el Historial"},
      {"id": "24h", "label": "Últimas 24 Horas"},
      {"id": "semana", "label": "Esta Semana"},
      {"id": "mes", "label": "Este Mes"},
      {"id": "3meses", "label": "Últimos 3 Meses"},
      {"id": "6meses", "label": "Últimos 6 Meses"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            // 📍 CAMBIO 1: Separamos el padding. Mantenemos 30 a los lados y 50 abajo,
            // pero reducimos el 'top' a 16 (o 12) para que la rayita suba casi al borde.
            padding:
                const EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    // Aquí mantienes tu margen inferior actual de 7 respecto a su propio contenedor
                    margin: const EdgeInsets.only(bottom: 7),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  // 1. Cambiamos a 'start' para controlar la distribución nosotros mismos
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Filtros avanzados",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 25,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    // 2. El Spacer empuja todo lo que esté a su derecha hasta el fondo
                    const Spacer(),

                    // 3. Envolvemos el botón en un Padding para controlar su distancia exacta del borde
                    Padding(
                      padding: const EdgeInsets.only(
                          right:
                              0), // 📍 MODIFICA ESTE NÚMERO: A mayor número, más se mueve a la izquierda. Con '0' queda pegado totalmente a la derecha.
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            tempRangoFecha = "24h";
                            tempUserController.clear();
                          });
                        },
                        icon: const Icon(Icons.restart_alt_rounded,
                            size: 30, color: Color(0xFF3B82F6)),
                        label: Text(
                          "(R)",
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B82F6)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ==========================================================================
                // CONDICIONAL DE ROL: SECCIÓN A (Solo se dibuja si el usuario es Administrador)
                // ==========================================================================
                if (esAdmin) ...[
                  Text(
                    "FILTRAR POR OPERARIO DE ALMACÉN (OPA)",
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 20),
                  _buildModernField(
                    controller: tempUserController,
                    label: "Escribe el username exacto del OPA",
                    icon: Icons.person_search_rounded,
                  ),
                  const SizedBox(height: 20),
                ],

                // SECCIÓN B: Rango de fecha (Disponible para TODOS los roles: Admin, OPA, OPT)
                Text(
                  "RANGO DE TIEMPO (FECHA DE CREACIÓN)",
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 19),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: opcionesTiempo.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.4,
                  ),
                  itemBuilder: (context, index) {
                    final opcion = opcionesTiempo[index];
                    final bool seleccionado = tempRangoFecha == opcion["id"];

                    return GestureDetector(
                      onTap: () {
                        setModalState(() => tempRangoFecha = opcion["id"]!);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: seleccionado
                              ? const Color(0xFF0059FF)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: seleccionado
                                ? const Color(0xFF0059FF)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          opcion["label"]!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: seleccionado
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 19),
                          side: const BorderSide(
                              color: Color.fromARGB(255, 255, 0, 0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "CANCELAR",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 0, 0),
                              fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 19),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          setState(() {
                            _filterRangoFecha = tempRangoFecha;
                            // Si no es admin, nos aseguramos de mandar siempre vacío el filtro de OPA
                            _filterUsername =
                                esAdmin ? tempUserController.text.trim() : "";
                          });
                          Navigator.pop(context);
                          _loadData(); // Dispara la actualización al servidor
                        },
                        child: Text(
                          "APLICAR FILTROS",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    String? label,
    Widget? child,
    bool isIcon = false,
  }) {
    bool isActive = _selectedCategory == id;

    // Determinamos el color dinámico según la categoría elegida cuando está activa
    Color activeColor;
    if (isActive) {
      switch (id) {
        case "Buenos":
          activeColor = const Color.fromARGB(
              255, 2, 223, 72); // Verde esmeralda para Buenos
          break;
        case "Alerta":
          activeColor =
              const Color(0xFFF59E0B); // Ámbar/Amarillo industrial para Alerta
          break;
        case "Critico":
          activeColor = const Color(0xFFEF4444); // Rojo vibrante para Crítico
          break;
        default:
          activeColor = const Color(
              0xFF0059FF); // Azul actual para el check (Entregados) o cualquier otro
      }
    } else {
      activeColor =
          const Color.fromARGB(116, 255, 255, 255); // Color base inactivo
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            // SI YA ESTÁ SELECCIONADO, SE APAGA Y MUESTRA TODOS LOS LOTES
            _selectedCategory = "Todos";
          } else {
            // SI NO ESTABA SELECCIONADO, SE ACTIVA NORMALMENTE
            _selectedCategory = id;
          }
        });
      },
      child: Container(
        // Si es icono (el check), le damos un ancho fijo pequeño
        // Si es texto, DEJAMOS QUE EL EXPANDED DE ARRIBA MANDE
        width: isIcon ? 45 : null,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activeColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? activeColor : const Color(0xFFE2E8F0)),
        ),
        child: isIcon
            ? IconTheme(
                data: IconThemeData(
                    color: isActive ? Colors.white : const Color(0xFF64748B)),
                child: child!,
              )
            : Text(
                label!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize:
                      12, // Mantén 12 para que el texto no se amontone en teléfonos mini
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusIndicator(Lote lote) {
    final String estadoStr = lote.estadoActual.toUpperCase();

    // Mapeo contextual y dinámico de iconografía
    IconData statusIcon;

    // 🎨 AQUÍ SE CONTROLA EL COLOR:
    // Por defecto usa "lote.colorEstado". Si quieres cambiar los colores manualmente,
    // puedes modificar los bloques "const Color(...)" de abajo a tu gusto.
    Color iconColor;

    if (estadoStr.contains('CRITICO')) {
      statusIcon = Icons.error_rounded; // Alarma de peligro inminente
      iconColor =
          const Color(0xFFEF4444); // 🔴 Rojo personalizado si quieres forzarlo
    } else if (estadoStr.contains('ALERTA')) {
      statusIcon = Icons.warning_rounded; // Alarma preventiva
      iconColor = const Color(0xFFF59E0B); // 🟡 Amarillo/Ámbar personalizado
    } else if (estadoStr.contains('OPTIMO')) {
      statusIcon = Icons.inventory_2_rounded; // El icono de caja/lote seguro
      iconColor = const Color.fromARGB(255, 14, 216,
          51); // 🟢 Verde actual (cámbialo aquí si deseas otro tono)
    } else {
      // Estado "ESPERANDO" o cualquier variable de incertidumbre
      statusIcon =
          Icons.pending_actions_rounded; // Reloj de expectativa logística
      iconColor = const Color(0xFF0059FF); // 🔵 Azul industrial forzado
    }

    return Container(
      padding: const EdgeInsets.all(
          12), // Espaciado interno perfecto para envolver el icono
      decoration: BoxDecoration(
        // Cambia el color de fondo de la cajita (usa el mismo color pero con 10% de opacidad)
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        statusIcon,
        color: iconColor, // Cambia el color del icono interno en sí
        size: 21,
      ),
    );
  }

  Widget _buildMiniBadge(Lote lote) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: lote.colorEstado.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        lote.estadoActual,
        style: GoogleFonts.inter(
            color: lote.colorEstado, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 60, color: Color(0xFFEF4444)),
            const SizedBox(height: 20),
            Text(
              "ERROR DE COMUNICACIÓN",
              style: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: GoogleFonts.inter(
                  color: const Color(0xFF64748B), fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("REINTENTAR ENLACE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 50, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text("SIN FLUJOS DE DATOS",
              style: GoogleFonts.robotoMono(
                  color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- MODALES DE ACCIÓN ---

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:
                  40, // Corregido el ancho del indicador superior para que sea visible y elegante
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Text("GESTIÓN DE LOGÍSTICA",
                style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF64748B))),
            const SizedBox(height: 20),
            if (widget.role == "admin" || widget.role == "OPA")
              _buildMenuOption(
                icon: Icons.add_box_rounded,
                label: "CREAR NUEVO LOTE",
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  _showFormModal(tipo: "crear");
                },
              ),
            if (widget.role == "OPT")
              _buildMenuOption(
                icon: Icons.link_rounded,
                label: "VINCULAR CUSTODIA",
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  _showFormModal(tipo: "vincular");
                },
              ),
            if (widget.role == "admin" || widget.role == "OPT")
              _buildMenuOption(
                icon: Icons.domain_verification_rounded,
                label: "MARCAR COMO ENTREGADO",
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(context);
                  _showFormModal(tipo: "entregar");
                },
              ),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MOTOR DE FORMULARIOS DINÁMICO ---
  void _showFormModal({required String tipo}) {
    _currentFormType = tipo;
    _clearControllers();
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(
                  tipo == "crear"
                      ? "NUEVO DESPACHO"
                      : (tipo == "vincular"
                          ? "MONITOREAR UNIDAD"
                          : "CONFIRMAR ENTREGA"),
                  style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                _buildModernField(
                    controller: _codigoController,
                    label: tipo == "entregar"
                        ? "NOMBRE DEL LOTE"
                        : "CÓDIGO DE LOTE",
                    icon: tipo == "entregar"
                        ? Icons.label_important_rounded
                        : Icons.qr_code_scanner_rounded),
                const SizedBox(height: 16),
                _buildModernField(
                    controller: (tipo == "entregar" || tipo == "vincular")
                        ? _nombreOpaController
                        : _productoController,
                    label: (tipo == "entregar" || tipo == "vincular")
                        ? "NOMBRE DEL OPA (EMISOR)"
                        : "PRODUCTO / CARGA",
                    icon: (tipo == "entregar" || tipo == "vincular")
                        ? Icons.person_pin_rounded
                        : Icons.inventory_2_outlined),
                const SizedBox(height: 16),
                if (tipo != "entregar" && tipo != "vincular") ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildModernField(
                              controller: _tempMinController,
                              label: "MIN °C",
                              icon: Icons.ac_unit_rounded,
                              isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildModernField(
                              controller: _tempMaxController,
                              label: "MAX °C",
                              icon: Icons.wb_sunny_rounded,
                              isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                _buildModernField(
                    controller: _passwordLoteController,
                    label: "CONTRASEÑA DE SEGURIDAD",
                    icon: Icons.lock_outline_rounded,
                    isPassword: true),
                if (localError != null)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.redAccent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(localError!,
                                  style: GoogleFonts.inter(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipo == "entregar"
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoadingAction
                        ? null
                        : () async {
                            final errorMsg = _validarFormularioLote();
                            if (errorMsg != null) {
                              setModalState(() => localError = errorMsg);
                              return;
                            }

                            setModalState(() => _isLoadingAction = true);
                            setState(() => _isLoadingAction = true);

                            try {
                              final String codigo =
                                  _codigoController.text.trim();
                              final String password =
                                  _passwordLoteController.text.trim();

                              if (tipo == "crear") {
                                final double min = double.parse(
                                    _tempMinController.text
                                        .replaceAll(',', '.'));
                                final double max = double.parse(
                                    _tempMaxController.text
                                        .replaceAll(',', '.'));

                                await _loteService.createLote(widget.token, {
                                  "codigo_lote": codigo,
                                  "producto": _productoController.text.trim(),
                                  "temp_min_ideal": min,
                                  "temp_max_ideal": max,
                                  "password_lote": password,
                                });
                              } else if (tipo == "vincular") {
                                await _loteService.vincularLote(widget.token, {
                                  "nombre_opa":
                                      _nombreOpaController.text.trim(),
                                  "codigo_lote": codigo,
                                  "password_lote": password,
                                });
                              } else if (tipo == "entregar") {
                                await _loteService.entregarLote(widget.token, {
                                  "nombre_opa":
                                      _nombreOpaController.text.trim(),
                                  "codigo_lote": codigo,
                                  "password_lote": password,
                                });
                              }

                              if (mounted) {
                                _isLoadingAction = false;
                                Navigator.pop(context);
                                _loadData();
                                _clearControllers();
                              }
                            } catch (e) {
                              setModalState(() {
                                _isLoadingAction = false;
                                localError =
                                    e.toString().replaceAll("Exception:", "");
                              });
                              setState(() => _isLoadingAction = false);
                            }
                          },
                    child: _isLoadingAction
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            tipo == "entregar"
                                ? "FINALIZAR ENTREGA"
                                : "CONFIRMAR REGISTRO",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    bool isPassword = false,
    String?
        errorText, // 👈 Convertido de forma correcta a Parámetro Opcional para evitar crasheos de compilación
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: errorText != null
                ? Border.all(color: Colors.redAccent, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              labelStyle:
                  const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: Icon(icon,
                  size: 20,
                  color: errorText != null
                      ? Colors.redAccent
                      : const Color(0xFF3B82F6)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              errorText,
              style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }

  // ==========================================================================
  // 📍 NUEVA FUNCIÓN: DIÁLOGO DESPLEGABLE DE CIERRE DE SESIÓN (ESTILO PREMIUM)
  // ==========================================================================

  Widget _buildMenuOption(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
      onTap: onTap,
    );
  }
}
