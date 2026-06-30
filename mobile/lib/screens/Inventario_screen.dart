import 'dart:async';
import 'package:flutter/material.dart';
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
  static const Color _bgColor = Color(0xFFF2F2F7);
  static const Color _cardColor = Colors.white;
  static const Color _titleColor = Color(0xFF1C1C1E);
  static const Color _labelGray = Color(0xFF8E8E93);
  static const Color _appleBlue = Color(0xFF007AFF);

  final LoteService _loteService = LoteService();
  late Future<List<Lote>> _futureLotes;

  // Lista live — se actualiza silenciosamente sin tocar el FutureBuilder
  List<Lote>? _lotesLive;
  Timer? _pollingTimer;

  String _selectedCategory = "Todos";
  final _searchController = TextEditingController();

  final _codigoController = TextEditingController();
  final _productoController = TextEditingController();
  final _tempMinController = TextEditingController();
  final _tempMaxController = TextEditingController();
  final _passwordLoteController = TextEditingController();
  final _nombreOpaController = TextEditingController();

  String _filterRangoFecha = "24h";
  String _filterUsername = "";

  bool _isLoadingAction = false;
  String _currentFormType = "";

  String get _normalizedRole {
    switch (widget.role.toLowerCase()) {
      case 'administrador':
      case 'admin':
        return 'admin';
      case 'operario':
      case 'opa':
        return 'OPA';
      case 'transportista':
      case 'opt':
        return 'OPT';
      default:
        return widget.role;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    // Polling silencioso cada 15 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _silentRefresh();
    });
  }

  // Resuelve el username a filtrar según el rol:
  // - Admin: usa _filterUsername (el que escribe en filtros avanzados)
  // - OPT/OPA/otros: sin filtro de username (el backend filtra por token)
  String? get _usernameParaFiltro {
    if (_filterUsername.trim().isNotEmpty) return _filterUsername.trim();
    return null;
  }

  // Carga inicial — usa FutureBuilder, muestra spinner la primera vez
  void _loadData() {
    setState(() {
      _futureLotes = _loteService
          .fetchLotes(
        widget.token,
        username: _usernameParaFiltro,
        // OPT usa "all" para ver sus lotes vinculados sin importar cuándo fueron creados
        rangoFecha: _normalizedRole == 'OPT' ? 'all' : _filterRangoFecha,
      )
          .then((lotes) {
        if (mounted) setState(() => _lotesLive = lotes);
        return lotes;
      });
    });
  }

  // Actualización silenciosa — solo toca _lotesLive, sin spinner
  Future<void> _silentRefresh() async {
    try {
      final lotes = await _loteService.fetchLotes(
        widget.token,
        username: _usernameParaFiltro,
        rangoFecha: _normalizedRole == 'OPT' ? 'all' : _filterRangoFecha,
      );
      if (!mounted) return;
      setState(() => _lotesLive = lotes);
    } catch (_) {
      // Fallo silencioso — no interrumpe la UI
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _codigoController.dispose();
    _productoController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _passwordLoteController.dispose();
    _nombreOpaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _validarFormularioLote() {
    if (_codigoController.text.trim().isEmpty)
      return "El Código/Nombre del lote es obligatorio";
    if (_passwordLoteController.text.trim().length < 4)
      return "La contraseña de seguridad debe tener al menos 4 caracteres";
    switch (_currentFormType) {
      case "crear":
        if (_productoController.text.trim().isEmpty)
          return "Debe especificar el producto para el registro";
        return _validarRangosTermicos();
      case "vincular":
        return null;
      case "entregar":
        if (_nombreOpaController.text.trim().isEmpty)
          return "El nombre del OPA emisor es obligatorio para la entrega";
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
    if (min == null || max == null) return "Las temperaturas deben ser números";
    if (min > max) return "Mínimo no puede ser mayor al máximo";
    if (min == max) return "Debe existir un rango operativo (Min ≠ Max)";
    if (min < -50.0 || max > 100.0)
      return "Rango fuera de límites del sensor (-50°C a 100°C)";
    if (_passwordLoteController.text.length < 4)
      return "Password debe tener min. 4 caracteres";
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
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // FAB con permisos corregidos
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: null,
      body: FutureBuilder<List<Lote>>(
        future: _futureLotes,
        builder: (context, snapshot) {
          // Para el header y la búsqueda usamos _lotesLive si ya existe,
          // si no, los datos del snapshot
          final List<Lote>? lotesParaHeader = _lotesLive ?? snapshot.data;

          return Column(
            children: [
              _buildHeader(lotesParaHeader),
              _buildSearchAndFilterSection(lotesParaHeader),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  color: _appleBlue,
                  onRefresh: () async => _loadData(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        // Para la lista de cards también usamos _lotesLive si existe
                        sliver: _lotesLive != null
                            ? _buildSliverFromLotes(_lotesLive!)
                            : _buildSliverContent(snapshot),
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

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(List<Lote>? lotes) {
    String total = "...", buenos = "...", alerta = "...", critico = "...";

    if (lotes != null) {
      final activos = lotes.where((l) => !l.entregado).toList();
      int b = 0, a = 0, c = 0;
      for (var lote in activos) {
        final e = lote.estadoActual.toUpperCase();
        if (e.contains('OPTIMO'))
          b++;
        else if (e.contains('ALERTA'))
          a++;
        else if (e.contains('CRITICO')) c++;
      }
      total = activos.length.toString();
      buenos = b.toString();
      alerta = a.toString();
      critico = c.toString();
    }

    return Container(
      width: double.infinity,
      color: _bgColor,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Inventario',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                  color: _titleColor,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE).withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Color.fromARGB(255, 79, 182, 255), size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Gestión de productos refrigerados',
            style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 40, 40, 48),
                letterSpacing: -0.2,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildStatCard(
                  total, "Total", const Color(0xFF6B7280), Colors.white),
              const SizedBox(width: 8),
              _buildStatCard(buenos, "Buenos", const Color(0xFF16A34A),
                  const Color(0xFF22C55E)),
              const SizedBox(width: 8),
              _buildStatCard(alerta, "Alerta", const Color(0xFFD97706),
                  const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildStatCard(critico, "Crítico", const Color(0xFFDC2626),
                  const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String value, String label, Color textColor, Color bgOrAccent) {
    final bool isTotal = label == "Total";
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isTotal ? Colors.white : bgOrAccent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTotal
                ? const Color(0xFFE2E8F0)
                : bgOrAccent.withValues(alpha: 0.0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isTotal ? 0.04 : 0.10),
              blurRadius: isTotal ? 6 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: isTotal ? textColor : Colors.white),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  color: isTotal
                      ? textColor
                      : Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH + CHIPS ─────────────────────────────────────────────────────────
  Widget _buildSearchAndFilterSection(List<Lote>? lotes) {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    style: const TextStyle(
                        fontSize: 15, color: _titleColor, letterSpacing: -0.2),
                    decoration: const InputDecoration(
                      hintText: "Buscar producto...",
                      hintStyle: TextStyle(color: _labelGray, fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: _labelGray, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: (_filterUsername.isNotEmpty ||
                            _filterRangoFecha != "24h")
                        ? _appleBlue.withValues(alpha: 0.4)
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
                        ? _appleBlue
                        : _labelGray,
                    size: 22,
                  ),
                  onPressed: () => _openAdvancedFilterModal(lotes),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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

  Widget _buildFilterChip(
      {required String id, String? label, Widget? child, bool isIcon = false}) {
    final bool isActive = _selectedCategory == id;
    Color chipColor;
    switch (id) {
      case "Buenos":
        chipColor = const Color(0xFF22C55E);
        break;
      case "Alerta":
        chipColor = const Color(0xFFF59E0B);
        break;
      case "Critico":
        chipColor = const Color(0xFFEF4444);
        break;
      default:
        chipColor = _appleBlue;
    }
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = isActive ? "Todos" : id),
      child: Container(
        width: isIcon ? 48 : null,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: chipColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ],
        ),
        child: isIcon
            ? IconTheme(
                data: IconThemeData(color: isActive ? Colors.white : chipColor),
                child: child!)
            : Text(
                label!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.3,
                    color: isActive ? Colors.white : Colors.black),
              ),
      ),
    );
  }

  // ── SLIVER — carga inicial (con spinner) ───────────────────────────────────
  Widget _buildSliverContent(AsyncSnapshot<List<Lote>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverFillRemaining(
        child: Center(
            child:
                CircularProgressIndicator(strokeWidth: 2.5, color: _appleBlue)),
      );
    }
    if (snapshot.hasError) {
      return SliverFillRemaining(
          child: _buildErrorState(snapshot.error.toString()));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }
    return _buildSliverFromLotes(snapshot.data!);
  }

  // ── SLIVER — construye las cards desde una lista (usada tanto en inicial como en live) ──
  Widget _buildSliverFromLotes(List<Lote> lotes) {
    if (lotes.isEmpty) return SliverFillRemaining(child: _buildEmptyState());

    final filtered = _getFilteredLotes(lotes);

    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: _labelGray),
              SizedBox(height: 14),
              Text("No se encontraron resultados",
                  style: TextStyle(
                      color: _labelGray,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2)),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildLoteCard(filtered[index]),
        childCount: filtered.length,
      ),
    );
  }

  // ── LOTE CARD ──────────────────────────────────────────────────────────────
  Widget _buildLoteCard(Lote lote) {
    final String estadoStr = lote.estadoActual.toUpperCase();
    IconData statusIcon;
    Color statusColor;
    if (estadoStr.contains('CRITICO')) {
      statusIcon = Icons.error_rounded;
      statusColor = const Color(0xFFEF4444);
    } else if (estadoStr.contains('ALERTA')) {
      statusIcon = Icons.warning_rounded;
      statusColor = const Color(0xFFF59E0B);
    } else if (estadoStr.contains('OPTIMO')) {
      statusIcon = Icons.inventory_2_rounded;
      statusColor = const Color(0xFF0EDE33);
    } else {
      statusIcon = Icons.pending_actions_rounded;
      statusColor = const Color.fromARGB(255, 30, 86, 240);
    }
    final String transportista =
        (lote.custodioUsername != null && lote.custodioUsername!.isNotEmpty)
            ? lote.custodioUsername!
            : "—";
    final String ultimaTemp = lote.ultimaTemperatura != null
        ? "${lote.ultimaTemperatura!.toStringAsFixed(1)}°C"
        : "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    LoteDetailScreen(token: widget.token, loteId: lote.id)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner de estado
              Container(
                height: 110,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.07),
                  border: Border(
                      bottom: BorderSide(
                          color: statusColor.withValues(alpha: 0.1), width: 1)),
                ),
                child: Stack(
                  children: [
                    Center(
                        child: Icon(statusIcon,
                            color: statusColor.withValues(alpha: 0.45),
                            size: 48)),
                    if (!estadoStr.contains('ESPERANDO'))
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            lote.entregado ? "ENTREGADO" : "EN TRÁNSITO",
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Datos
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(lote.codigoLote,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: _titleColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            letterSpacing: -0.5)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: lote.colorEstado
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(lote.estadoActual,
                                        style: TextStyle(
                                            color: lote.colorEstado,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.2)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(lote.producto.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: _labelGray,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                          color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataRow(
                                  icon: Icons.arrow_downward_rounded,
                                  iconColor: _appleBlue,
                                  label: "Mín:",
                                  value:
                                      "${lote.tempMinIdeal.toStringAsFixed(1)}°C"),
                              const SizedBox(height: 6),
                              _buildDataRow(
                                  icon: Icons.arrow_upward_rounded,
                                  iconColor: const Color(0xFFEF4444),
                                  label: "Máx:",
                                  value:
                                      "${lote.tempMaxIdeal.toStringAsFixed(1)}°C"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDataRow(
                                  icon: Icons.thermostat_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  label: "Temp:",
                                  value: ultimaTemp),
                              const SizedBox(height: 6),
                              _buildDataRow(
                                  icon: Icons.local_shipping_rounded,
                                  iconColor: _labelGray,
                                  label: "Conductor:",
                                  value: transportista),
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

  Widget _buildDataRow(
      {required IconData icon,
      required Color iconColor,
      required String label,
      required String value}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: _labelGray,
                letterSpacing: -0.1)),
        const SizedBox(width: 4),
        Expanded(
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                    letterSpacing: -0.2))),
      ],
    );
  }

  // ── ESTADOS ────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 48, color: _labelGray.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          const Text("Sin datos",
              style: TextStyle(
                  color: _labelGray,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2)),
        ],
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
                size: 52, color: Color(0xFFEF4444)),
            const SizedBox(height: 18),
            const Text("Error de comunicación",
                style: TextStyle(
                    color: _titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(error,
                style: const TextStyle(color: _labelGray, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _titleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: const Text("Reintentar",
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── MODAL FILTROS ──────────────────────────────────────────────────────────
  void _openAdvancedFilterModal(List<Lote>? lotes) {
    final bool esAdmin = _normalizedRole == 'admin';
    String tempRangoFecha = _filterRangoFecha;
    final tempUserController =
        TextEditingController(text: esAdmin ? _filterUsername : "");
    final List<Map<String, String>> opciones = [
      {"id": "all", "label": "Todo el historial"},
      {"id": "24h", "label": "Últimas 24 h"},
      {"id": "semana", "label": "Esta semana"},
      {"id": "mes", "label": "Este mes"},
      {"id": "3meses", "label": "Últimos 3 meses"},
      {"id": "6meses", "label": "Últimos 6 meses"},
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 40),
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
                            borderRadius: BorderRadius.circular(10)))),
                Row(
                  children: [
                    const Text("Filtros avanzados",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: -0.8,
                            color: _titleColor)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setModalState(() {
                        tempRangoFecha = "24h";
                        tempUserController.clear();
                      }),
                      icon: const Icon(Icons.restart_alt_rounded,
                          size: 20, color: _appleBlue),
                      label: const Text("Resetear",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _appleBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (esAdmin) ...[
                  const Text("FILTRAR POR OPA",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _labelGray,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  _buildModalInputField(
                      controller: tempUserController,
                      hint: "Username exacto del OPA"),
                  const SizedBox(height: 20),
                ],
                // OPT no necesita filtro de fecha — siempre ve todos sus lotes vinculados
                if (_normalizedRole != 'OPT') ...[
                  const Text("RANGO DE TIEMPO",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _labelGray,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: opciones.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 3.5),
                    itemBuilder: (context, index) {
                      final op = opciones[index];
                      final bool sel = tempRangoFecha == op["id"];
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => tempRangoFecha = op["id"]!),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel ? _appleBlue : _cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    sel ? _appleBlue : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(op["label"]!,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  color: sel ? Colors.white : _labelGray)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Mensaje informativo para OPT
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _appleBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _appleBlue.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: _appleBlue, size: 16),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Como transportista ves todos tus lotes vinculados sin límite de fecha.",
                            style: TextStyle(
                                color: _appleBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _titleColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0),
                        onPressed: () {
                          setState(() {
                            _filterRangoFecha = tempRangoFecha;
                            _filterUsername =
                                esAdmin ? tempUserController.text.trim() : "";
                            _lotesLive =
                                null; // reset live para forzar spinner en el nuevo filtro
                          });
                          Navigator.pop(context);
                          _loadData();
                        },
                        child: const Text("Aplicar",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 15)),
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

  // ── ACTION MENU ────────────────────────────────────────────────────────────
  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 22),
            const Text("GESTIÓN DE LOGÍSTICA",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _labelGray,
                    letterSpacing: 0.5)),
            const SizedBox(height: 16),
            if (_normalizedRole == 'admin' || _normalizedRole == 'OPA')
              _buildMenuOption(
                  icon: Icons.add_box_rounded,
                  label: "Crear nuevo lote",
                  color: _appleBlue,
                  onTap: () {
                    Navigator.pop(context);
                    _showFormModal(tipo: "crear");
                  }),
            if (_normalizedRole == 'OPT')
              _buildMenuOption(
                  icon: Icons.link_rounded,
                  label: "Vincular custodia",
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.pop(context);
                    _showFormModal(tipo: "vincular");
                  }),
            if (_normalizedRole == 'admin' || _normalizedRole == 'OPT')
              _buildMenuOption(
                  icon: Icons.domain_verification_rounded,
                  label: "Marcar como entregado",
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.pop(context);
                    _showFormModal(tipo: "entregar");
                  }),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1)),
                  child: const Icon(Icons.close_rounded,
                      size: 22, color: _labelGray),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          child: Icon(icon, color: color, size: 22)),
      title: Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: -0.3,
              color: _titleColor)),
      onTap: onTap,
    );
  }

  // ── MODAL FORMULARIO ───────────────────────────────────────────────────────
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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                            borderRadius: BorderRadius.circular(10)))),
                Text(
                  tipo == "crear"
                      ? "Nuevo despacho"
                      : (tipo == "vincular"
                          ? "Vincular unidad"
                          : "Confirmar entrega"),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.8,
                      color: _titleColor),
                ),
                const SizedBox(height: 22),
                _buildFormSection(
                    child: Column(children: [
                  _buildFormField(
                      controller: _codigoController,
                      hint: tipo == "entregar"
                          ? "Nombre del lote"
                          : "Código de lote",
                      enabled: !_isLoadingAction),
                  const Divider(height: 1, indent: 16),
                  _buildFormField(
                    controller: (tipo == "entregar" || tipo == "vincular")
                        ? _nombreOpaController
                        : _productoController,
                    hint: (tipo == "entregar" || tipo == "vincular")
                        ? "Nombre del OPA (emisor)"
                        : "Producto / carga",
                    enabled: !_isLoadingAction,
                  ),
                ])),
                if (tipo != "entregar" && tipo != "vincular") ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _buildFormSection(
                            child: _buildFormField(
                                controller: _tempMinController,
                                hint: "Mín °C",
                                isNumber: true,
                                enabled: !_isLoadingAction))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildFormSection(
                            child: _buildFormField(
                                controller: _tempMaxController,
                                hint: "Máx °C",
                                isNumber: true,
                                enabled: !_isLoadingAction))),
                  ]),
                ],
                const SizedBox(height: 14),
                _buildFormSection(
                    child: _buildFormField(
                        controller: _passwordLoteController,
                        hint: "Contraseña de seguridad",
                        isPassword: true,
                        enabled: !_isLoadingAction)),
                if (localError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.25))),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(localError!,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tipo == "entregar"
                          ? const Color(0xFFF59E0B)
                          : _titleColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
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
                              final codigo = _codigoController.text.trim();
                              final password =
                                  _passwordLoteController.text.trim();
                              if (tipo == "crear") {
                                final min = double.parse(_tempMinController.text
                                    .replaceAll(',', '.'));
                                final max = double.parse(_tempMaxController.text
                                    .replaceAll(',', '.'));
                                await _loteService.createLote(widget.token, {
                                  "codigo_lote": codigo,
                                  "producto": _productoController.text.trim(),
                                  "temp_min_ideal": min,
                                  "temp_max_ideal": max,
                                  "password_lote": password
                                });
                              } else if (tipo == "vincular") {
                                await _loteService.vincularLote(widget.token, {
                                  "nombre_opa":
                                      _nombreOpaController.text.trim(),
                                  "codigo_lote": codigo,
                                  "password_lote": password
                                });
                              } else if (tipo == "entregar") {
                                await _loteService.entregarLote(widget.token, {
                                  "nombre_opa":
                                      _nombreOpaController.text.trim(),
                                  "codigo_lote": codigo,
                                  "password_lote": password
                                });
                              }
                              if (context.mounted) {
                                _isLoadingAction = false;
                                Navigator.pop(context);
                                _loadData();
                                _clearControllers();
                              }
                            } catch (e) {
                              setModalState(() {
                                _isLoadingAction = false;
                                localError = e
                                    .toString()
                                    .replaceAll("Exception:", "")
                                    .trim();
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
                                ? "Finalizar entrega"
                                : "Confirmar registro",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: child,
    );
  }

  Widget _buildFormField(
      {required TextEditingController controller,
      required String hint,
      bool isNumber = false,
      bool isPassword = false,
      bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        enabled: enabled,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(
            fontSize: 16,
            color: _titleColor,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF515151), fontSize: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildModalInputField(
      {required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: controller,
          style: const TextStyle(
              fontSize: 15,
              color: _titleColor,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w300),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF515151), fontSize: 15),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
