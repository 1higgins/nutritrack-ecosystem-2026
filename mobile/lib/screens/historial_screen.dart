import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//ESTA PANTALLA NO TIENE USO PERO TIENE FUNCIONALIDAD, PUEDES GUIARTE DE ALGUNA LOGICA

// ─── Model ────────────────────────────────────────────────────────────────────
enum RegistroStatus { bueno, alerta, critico }

class RegistroHistorial {
  final String id;
  final String productName;
  final String lot;
  final double temperature;
  final String location;
  final DateTime timestamp;
  final RegistroStatus status;
  final String createdBy;
  final String createdByRole;

  const RegistroHistorial({
    required this.id,
    required this.productName,
    required this.lot,
    required this.temperature,
    required this.location,
    required this.timestamp,
    required this.status,
    required this.createdBy,
    required this.createdByRole,
  });

  /// Factory para construir desde JSON del backend.
  /// Ejemplo de respuesta esperada:
  /// {
  ///   "id": "REC-001",
  ///   "product_name": "Carne Refrigerada",
  ///   "lot": "LOT-Z67DS1EE",
  ///   "temperature": -1.7,
  ///   "location": "Zona de Despacho",
  ///   "timestamp": "2026-05-15T13:16:00Z",
  ///   "status": "critico",          // "bueno" | "alerta" | "critico"
  ///   "created_by": "Carlos Ramos",
  ///   "created_by_role": "Operario"
  /// }
  factory RegistroHistorial.fromJson(Map<String, dynamic> json) {
    RegistroStatus parseStatus(String s) {
      switch (s.toLowerCase()) {
        case 'alerta':
          return RegistroStatus.alerta;
        case 'critico':
          return RegistroStatus.critico;
        default:
          return RegistroStatus.bueno;
      }
    }

    return RegistroHistorial(
      id: json['id'] as String,
      productName: json['product_name'] as String,
      lot: json['lot'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      location: json['location'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: parseStatus(json['status'] as String),
      createdBy: json['created_by'] as String,
      createdByRole: json['created_by_role'] as String,
    );
  }
}

// ─── HistorialService (stub listo para conectar) ─────────────────────────────
/// Reemplaza el body de cada método con tu llamada HTTP real.
///
/// Ejemplo con el package http:
///   import 'dart:convert';
///   import 'package:http/http.dart' as http;
///
///   static const _base = 'https://api.tudominio.com';
///
///   static Future<List<RegistroHistorial>> fetchHistorial({...}) async {
///     final uri = Uri.parse('$_base/historial').replace(
///       queryParameters: { if (from != null) 'from': from!.toIso8601String() });
///     final res = await http.get(uri,
///         headers: {'Authorization': 'Bearer $token'});
///     final List data = jsonDecode(res.body);
///     return data.map((e) => RegistroHistorial.fromJson(e)).toList();
///   }
class HistorialService {
  static Future<List<RegistroHistorial>> fetchHistorial({
    DateTime? from,
    DateTime? to,
  }) async {
    // ── Simula latencia de red ────────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 600));

    // ── TODO: reemplazar con llamada real ──────────────────────────────────
    // GET /historial?from=...&to=...
    final now = DateTime.now();
    return [
      RegistroHistorial(
        id: 'REC-001',
        productName: 'Carne Refrigerada',
        lot: 'LOT-Z67DS1EE',
        temperature: 8.5,
        location: 'Zona de Despacho',
        timestamp: now.subtract(const Duration(minutes: 5)),
        status: RegistroStatus.critico,
        createdBy: 'Carlos Ramos',
        createdByRole: 'Operario',
      ),
      RegistroHistorial(
        id: 'REC-002',
        productName: 'Lácteos Frescos',
        lot: 'LOT-K9AG55H7',
        temperature: 4.2,
        location: 'Almacén A',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        status: RegistroStatus.alerta,
        createdBy: 'María Flores',
        createdByRole: 'Supervisora',
      ),
      RegistroHistorial(
        id: 'REC-003',
        productName: 'Verduras Frescas',
        lot: 'LOT-000PTPW',
        temperature: -1.4,
        location: 'Almacén B',
        timestamp: now.subtract(const Duration(hours: 3)),
        status: RegistroStatus.bueno,
        createdBy: 'Luis Torres',
        createdByRole: 'Operario',
      ),
      RegistroHistorial(
        id: 'REC-004',
        productName: 'Pescado Congelado',
        lot: 'LOT-KEUH0SK0',
        temperature: 9.1,
        location: 'Cámara 1',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        status: RegistroStatus.critico,
        createdBy: 'Ana Medina',
        createdByRole: 'Supervisora',
      ),
      RegistroHistorial(
        id: 'REC-005',
        productName: 'Helados y Postres',
        lot: 'LOT-HEL44RX8',
        temperature: -14.3,
        location: 'Cámara 3',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        status: RegistroStatus.bueno,
        createdBy: 'Carlos Ramos',
        createdByRole: 'Operario',
      ),
    ];
  }

  static Future<void> deleteRegistro(String id) async {
    // TODO: DELETE /historial/:id
    await Future.delayed(const Duration(milliseconds: 400));
  }

  static Future<void> deleteAll() async {
    // TODO: DELETE /historial
    await Future.delayed(const Duration(milliseconds: 400));
  }
}

// ─── HistorialPage ────────────────────────────────────────────────────────────
class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  // ── Design tokens (mismos que InventarioPage) ──────────────────────────────
  static const Color bgColor = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color titleColor = Color(0xFF1C1C1E);
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color appleBlue = Color(0xFF007AFF);
  static const Color appleGreen = Color(0xFF30D158);
  static const Color appleOrange = Color(0xFFFF9F0A);
  static const Color appleRed = Color(0xFFFF453A);

  // ── State ──────────────────────────────────────────────────────────────────
  late Future<List<RegistroHistorial>> _future;
  RegistroStatus? _activeFilter;

  static const _dateOptions = [
    'Todas las fechas',
    'Hoy',
    'Ayer',
    'Últimos 7 días',
    'Últimos 30 días',
  ];
  String _selectedDate = 'Todas las fechas';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() {
    _future = HistorialService.fetchHistorial();
  });

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatDay(DateTime dt) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  bool _matchesDateFilter(DateTime dt) {
    final today = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final t = DateTime(today.year, today.month, today.day);
    switch (_selectedDate) {
      case 'Hoy':
        return d == t;
      case 'Ayer':
        return d == t.subtract(const Duration(days: 1));
      case 'Últimos 7 días':
        return d.isAfter(t.subtract(const Duration(days: 7)));
      case 'Últimos 30 días':
        return d.isAfter(t.subtract(const Duration(days: 30)));
      default:
        return true;
    }
  }

  List<RegistroHistorial> _applyFilters(List<RegistroHistorial> all) =>
      all.where((r) {
        final matchDate = _matchesDateFilter(r.timestamp);
        final matchStatus = _activeFilter == null || r.status == _activeFilter;
        return matchDate && matchStatus;
      }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  Map<String, List<RegistroHistorial>> _groupByDay(
    List<RegistroHistorial> list,
  ) {
    final map = <String, List<RegistroHistorial>>{};
    for (final r in list) {
      map.putIfAbsent(_formatDay(r.timestamp), () => []).add(r);
    }
    return map;
  }

  Future<void> _confirmDelete(RegistroHistorial r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar registro',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          '¿Eliminar el registro del lote ${r.lot}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: appleRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HistorialService.deleteRegistro(r.id);
      _load();
    }
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Limpiar historial',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: const Text(
          '¿Eliminar todos los registros? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar todo',
              style: TextStyle(color: appleRed),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HistorialService.deleteAll();
      _load();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: FutureBuilder<List<RegistroHistorial>>(
            future: _future,
            builder: (context, snap) {
              return CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historial',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.4,
                                    color: titleColor,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Registros de temperatura y lotes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: labelGray,
                                    letterSpacing: -0.2,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _load,
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: appleBlue.withOpacity(0.10),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: appleBlue,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _confirmDeleteAll,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: appleRed.withOpacity(0.10),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: appleRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Stats ──────────────────────────────────────────────
                  if (snap.hasData)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildStats(snap.data!),
                      ),
                    ),

                  // ── Date filter ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: _DateFilterCard(
                        options: _dateOptions,
                        selected: _selectedDate,
                        onChanged: (v) => setState(() => _selectedDate = v),
                      ),
                    ),
                  ),

                  // ── Status chips ────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        children: [
                          _FilterChip(
                            label: 'Todos',
                            isActive: _activeFilter == null,
                            onTap: () => setState(() => _activeFilter = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Bueno',
                            isActive: _activeFilter == RegistroStatus.bueno,
                            activeColor: appleGreen,
                            onTap: () => setState(
                              () => _activeFilter = RegistroStatus.bueno,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Alerta',
                            isActive: _activeFilter == RegistroStatus.alerta,
                            activeColor: appleOrange,
                            onTap: () => setState(
                              () => _activeFilter = RegistroStatus.alerta,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Crítico',
                            isActive: _activeFilter == RegistroStatus.critico,
                            activeColor: appleRed,
                            onTap: () => setState(
                              () => _activeFilter = RegistroStatus.critico,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Content ────────────────────────────────────────────
                  if (snap.connectionState == ConnectionState.waiting)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: appleBlue,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  else if (snap.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: labelGray,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Error al cargar datos',
                              style: TextStyle(
                                color: labelGray.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildList(snap.data!),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStats(List<RegistroHistorial> all) {
    final buenos = all.where((r) => r.status == RegistroStatus.bueno).length;
    final alerta = all.where((r) => r.status == RegistroStatus.alerta).length;
    final critico = all.where((r) => r.status == RegistroStatus.critico).length;
    return Row(
      children: [
        _StatCard(
          value: '${all.length}',
          label: 'Total',
          textColor: titleColor,
          bg: cardColor,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$buenos',
          label: 'Buenos',
          textColor: Colors.white,
          bg: appleGreen,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$alerta',
          label: 'Alerta',
          textColor: Colors.white,
          bg: appleOrange,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '$critico',
          label: 'Crítico',
          textColor: Colors.white,
          bg: appleRed,
        ),
      ],
    );
  }

  // ── Grouped list ───────────────────────────────────────────────────────────
  Widget _buildList(List<RegistroHistorial> all) {
    final filtered = _applyFilters(all);
    final grouped = _groupByDay(filtered);

    if (filtered.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: labelGray.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sin registros',
                style: TextStyle(
                  fontSize: 16,
                  color: labelGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final days = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, dayIndex) {
        final dayLabel = days[dayIndex];
        final registros = grouped[dayLabel]!;
        final isLast = dayIndex == days.length - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(
                dayLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelGray,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            // Cards
            ...registros.asMap().entries.map((e) {
              final idx = e.key;
              final r = e.value;
              final globalIdx = dayIndex * 10 + idx;
              final isLastCard = isLast && idx == registros.length - 1;

              return Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, isLastCard ? 32 : 10),
                child: _AnimatedRegistroCard(
                  index: globalIdx,
                  registro: r,
                  onDelete: () => _confirmDelete(r),
                  formatTime: _formatTime,
                ),
              );
            }),
          ],
        );
      }, childCount: days.length),
    );
  }
}

// ─── Date Filter Card ─────────────────────────────────────────────────────────
class _DateFilterCard extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _DateFilterCard({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  static const Color cardColor = Colors.white;
  static const Color titleColor = Color(0xFF1C1C1E);
  static const Color labelGray = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: const [
                Icon(Icons.calendar_month_rounded, size: 16, color: labelGray),
                SizedBox(width: 6),
                Text(
                  'Filtrar por fecha',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: labelGray,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DropdownButtonFormField<String>(
              value: selected,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: labelGray,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                fontSize: 15,
                color: titleColor,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color bg;

  const _StatCard({
    required this.value,
    required this.label,
    required this.textColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.75),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.activeColor = const Color(0xFF007AFF),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: isActive ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ),
    );
  }
}

// ─── Animated wrapper ─────────────────────────────────────────────────────────
class _AnimatedRegistroCard extends StatefulWidget {
  final int index;
  final RegistroHistorial registro;
  final VoidCallback onDelete;
  final String Function(DateTime) formatTime;

  const _AnimatedRegistroCard({
    required this.index,
    required this.registro,
    required this.onDelete,
    required this.formatTime,
  });

  @override
  State<_AnimatedRegistroCard> createState() => _AnimatedRegistroCardState();
}

class _AnimatedRegistroCardState extends State<_AnimatedRegistroCard>
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
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(
      position: _slide,
      child: _RegistroCard(
        registro: widget.registro,
        onDelete: widget.onDelete,
        formatTime: widget.formatTime,
      ),
    ),
  );
}

// ─── Registro Card ────────────────────────────────────────────────────────────
class _RegistroCard extends StatelessWidget {
  final RegistroHistorial registro;
  final VoidCallback onDelete;
  final String Function(DateTime) formatTime;

  const _RegistroCard({
    required this.registro,
    required this.onDelete,
    required this.formatTime,
  });

  static const Color titleColor = Color(0xFF1C1C1E);
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color appleBlue = Color(0xFF007AFF);
  static const Color appleGreen = Color(0xFF30D158);
  static const Color appleOrange = Color(0xFFFF9F0A);
  static const Color appleRed = Color(0xFFFF453A);

  Color get _bubbleColor {
    switch (registro.status) {
      case RegistroStatus.bueno:
        return appleGreen;
      case RegistroStatus.alerta:
        return appleOrange;
      case RegistroStatus.critico:
        return appleRed;
    }
  }

  ({String label, Color bg, Color fg}) get _statusStyle {
    switch (registro.status) {
      case RegistroStatus.bueno:
        return (
          label: 'Bueno',
          bg: appleGreen.withOpacity(0.12),
          fg: const Color(0xFF1A7A32),
        );
      case RegistroStatus.alerta:
        return (
          label: 'Alerta',
          bg: appleOrange.withOpacity(0.12),
          fg: const Color(0xFF8A5200),
        );
      case RegistroStatus.critico:
        return (
          label: 'Crítico',
          bg: appleRed.withOpacity(0.12),
          fg: const Color(0xFF9B1208),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = _statusStyle;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: product name · time · delete ─────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        registro.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        registro.lot,
                        style: const TextStyle(
                          fontSize: 12,
                          color: labelGray,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatTime(registro.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: labelGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appleRed.withOpacity(0.10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: appleRed,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            const SizedBox(height: 12),

            // ── Row 2: temp · status · location ─────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _bubbleColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${registro.temperature}°C',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ss.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ss.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ss.fg,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: labelGray,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      registro.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: labelGray,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF2F2F7)),
            const SizedBox(height: 10),

            // ── Row 3: creado por ─────────────────────────────────────────
            Row(
              children: [
                // Avatar inicial
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appleBlue.withOpacity(0.10),
                  ),
                  child: Center(
                    child: Text(
                      registro.createdBy.isNotEmpty
                          ? registro.createdBy[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: appleBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creado por ${registro.createdBy}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        registro.createdByRole,
                        style: const TextStyle(
                          fontSize: 11,
                          color: labelGray,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // ID del registro
                Text(
                  registro.id,
                  style: TextStyle(
                    fontSize: 10,
                    color: labelGray.withOpacity(0.55),
                    letterSpacing: 0,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
