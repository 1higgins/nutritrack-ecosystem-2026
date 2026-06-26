import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
<<<<<<< Updated upstream
import 'dart:async';
import 'dart:convert';
=======
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
>>>>>>> Stashed changes
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'inventario_screen.dart';

// ==========================================================================
// PALETA DE COLORES GLOBAL ESTILO INDUSTRIAL
// ==========================================================================
const Color bgColor = Color(0xFFF2F2F7);
const Color cardColor = Colors.white;
const Color titleColor = Color(0xFF1C1C1E);
const Color labelGray = Color(0xFF8E8E93);
const Color appleBlue = Color(0xFF007AFF);
const Color appleGreen = Color(0xFF30D158);
const Color appleOrange = Color(0xFFFF9F0A);
const Color appleRed = Color(0xFFFF453A);

class TelemetriaLocal {
  final DateTime fechaRegistro;
  final double temperatura;
  final double humedad;
  final String diagnostico; // Vinculado a alerts.py del backend

  const TelemetriaLocal({
    required this.fechaRegistro,
    required this.temperatura,
    required this.humedad,
    required this.diagnostico,
  });
}

class LoteDetailScreen extends StatefulWidget {
  final Product product;
  final String token;

  const LoteDetailScreen({
    super.key,
    required this.product,
    required this.token,
  });

  @override
  State<LoteDetailScreen> createState() => _LoteDetailScreenState();
}

class _LoteDetailScreenState extends State<LoteDetailScreen> {
<<<<<<< Updated upstream
  List<TelemetriaLocal> _telemetrias = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  int? _idLoteReal;
  double? _limiteMin;
  double? _limiteMax;
  double? _temperaturaActual;
  double? _promedioTemperatura;
  String _estadoActualServidor = "...";
=======
  // Colores estilo iOS
  static const Color _bgColor = Color(0xFFF2F2F7);
  static const Color _titleColor = Color(0xFF1C1C1E);
  static const Color _labelGray = Color(0xFF8E8E93);
  static const Color _appleBlue = Color(0xFF007AFF);

  final LoteService _loteService = LoteService();
  late Future<Map<String, dynamic>> _loteFuture;
  String _rangoSeleccionado = "24h";
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    _fetchHistorialLote(showLoading: true);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ==========================================================================
  // EXTRACCIÓN Y MAPEO EXACTO CON FASTAPI (CORREGIDO)
  // ==========================================================================
  // ==========================================================================
  // EXTRACCIÓN Y MAPEO EXACTO CON FASTAPI (CORREGIDO)
  // ==========================================================================
  Future<void> _fetchHistorialLote({required bool showLoading}) async {
    if (!mounted) return;
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final String codigoBuscado = widget.product.lote;
    String url = 'http://127.0.0.1:8000/lotes/';

    try {
      // 📍 REEMPLAZA DESDE AQUÍ:
      if (_idLoteReal == null) {
        final responseGlobal = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (responseGlobal.statusCode == 200) {
          final List<dynamic> listaLotes = json.decode(responseGlobal.body);
          for (var l in listaLotes) {
            if (l['codigo_lote'] == codigoBuscado) {
              _idLoteReal =
                  l['id']; // Se memoriza para los siguientes 3 segundos
              break;
            }
          }
        }
      }

      // Si no se encuentra un ID que coincida en la base de datos, usamos un fallback seguro
      final String endpointFinal = _idLoteReal != null ? '$_idLoteReal' : '1';
      final String urlDetalle = 'http://127.0.0.1:8000/lotes/$endpointFinal';
      // 📍 HASTA AQUÍ EL REEMPLAZO.

      // ⚠️ LO QUE SIGUE DE AQUÍ ABAJO SE QUEDA EXACTAMENTE IGUAL A COMO LO TENÍAS:
      final response = await http
          .get(
            Uri.parse(urlDetalle),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          .timeout(const Duration(seconds: 20000));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        _limiteMin = data['temp_min_ideal'] != null
            ? (data['temp_min_ideal'] as num).toDouble()
            : null;
        _limiteMax = data['temp_max_ideal'] != null
            ? (data['temp_max_ideal'] as num).toDouble()
            : null;
        _estadoActualServidor = data['estado_actual'] ?? "...";

        final List<dynamic> lecturasRaw = data['telemetrias'] ?? [];
        List<TelemetriaLocal> cargadas = [];
        double suma = 0;

        for (var item in lecturasRaw) {
          if (item['temperatura'] != null) {
            final double temp = (item['temperatura'] as num).toDouble();
            final double hum = item['humedad'] != null
                ? (item['humedad'] as num).toDouble()
                : 0.0;
            final String diag = item['diagnostico'] ?? "Sin diagnóstico.";

            DateTime fecha;
            if (item['fecha_registro'] != null) {
              fecha = DateTime.parse(item['fecha_registro']).toLocal();
            } else {
              fecha = DateTime.now();
            }

            cargadas.add(
              TelemetriaLocal(
                fechaRegistro: fecha,
                temperatura: temp,
                humedad: hum,
                diagnostico: diag,
              ),
            );
            suma += temp;
          }
        }

        cargadas.sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));

        if (!mounted) return;
        setState(() {
          _telemetrias = cargadas;
          _temperaturaActual = cargadas.isNotEmpty
              ? cargadas.last.temperatura
              : null;
          _promedioTemperatura = cargadas.isNotEmpty
              ? (suma / cargadas.length)
              : null;
          _isLoading = false;
        });
      } else {
        if (showLoading) _inicializarEstructurasVacias();
      }
    } catch (e) {
      if (showLoading) _inicializarEstructurasVacias();
=======
    _loadData();
  }

  void _loadData() {
    _loteFuture = _loteService.fetchLoteDetail(
      widget.token,
      widget.loteId,
      rangoFecha: _rangoSeleccionado,
    );
  }

  // ── LÓGICA SIN CAMBIOS ──────────────────────────────────────────────────────
  List<CartesianSeries<Telemetria, String>> _buildProfessionalSeries(
      List<Telemetria> telemetrias, Lote lote) {
    List<CartesianSeries<Telemetria, String>> series = [];
    if (telemetrias.isEmpty) return series;

    final data = List<Telemetria>.from(telemetrias)
      ..sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));

    series.add(LineSeries<Telemetria, String>(
      dataSource: data,
      xValueMapper: (t, _) => DateFormat('HH:mm:ss').format(t.fechaRegistro),
      yValueMapper: (t, _) => t.temperatura,
      animationDuration: 0,
      width: 1.5,
      color: const Color.fromARGB(255, 165, 178, 190),
      markerSettings: const MarkerSettings(
        isVisible: true,
        height: 3.5,
        width: 3.5,
        shape: DataMarkerType.circle,
        borderWidth: 1,
        borderColor: Color.fromARGB(255, 173, 175, 176),
      ),
      pointColorMapper: (t, _) {
        final bool isOptimal = t.temperatura <= lote.tempMaxIdeal &&
            t.temperatura >= lote.tempMinIdeal;
        return isOptimal ? const Color(0xFF00E5FF) : const Color(0xFFEF4444);
      },
    ));
    return series;
  }

  double getVisibleTopLimit(
      double axisMin, double axisMax, double interval, double idealMax) {
    List<double> visibleLabels = [];
    for (double v = axisMin; v <= axisMax; v += interval) {
      visibleLabels.add(v);
>>>>>>> Stashed changes
    }
  }
  // ── FIN LÓGICA ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: FutureBuilder<Map<String, dynamic>>(
          future: _loteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("Sin datos"));
            }

            final Map<String, dynamic> dataRaw = snapshot.data!;
            final Map<String, dynamic> loteJson = dataRaw.containsKey('lote')
                ? dataRaw['lote'] as Map<String, dynamic>
                : dataRaw;
            final lote = Lote.fromJson(loteJson);

            final List<dynamic> lecturasRaw =
                dataRaw['historial_lecturas'] ?? [];
            final List<Telemetria> listaTelemetrias = lecturasRaw
                .map((t) => Telemetria.fromJson(t as Map<String, dynamic>))
                .toList();

            final double? tempActualBackend =
                dataRaw['temperatura_actual'] != null
                    ? (dataRaw['temperatura_actual'] as num).toDouble()
                    : null;
            final double? tempPromedioBackend =
                dataRaw['temperatura_promedio'] != null
                    ? (dataRaw['temperatura_promedio'] as num).toDouble()
                    : null;

            return SafeArea(
              child: Column(
                children: [
                  // ── ENCABEZADO
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Temperatura",
                                    style: TextStyle(
                                      fontSize: 31,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1.4,
                                      color: _titleColor,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // Botón filtro de rango
                                      GestureDetector(
                                        onTap: () =>
                                            _showFilterBottomSheet(context),
                                        child: Container(
                                          height: 42,
                                          width: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE)
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.thermostat,
                                            color: Color.fromARGB(
                                                255, 81, 147, 233),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Botón home / volver
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Container(
                                          height: 42,
                                          width: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE)
                                                .withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.home_rounded,
                                            color: Color.fromARGB(
                                                255, 81, 147, 233),
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _buildSubtituloFiltro(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _labelGray,
                                  letterSpacing: -0.2,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── CUADRÍCULA DE MÉTRICAS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildNewMetricsGrid(lote, listaTelemetrias,
                        tempActualBackend, tempPromedioBackend),
                  ),

                  const SizedBox(height: 20),

                  // ── ÁREA SCROLLABLE CON REFRESH
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => setState(() => _loadData()),
                      color: const Color(0xFF3B82F6),
                      edgeOffset: 0,
                      displacement: 20,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showFullScreenChart(
                                  context, listaTelemetrias, lote),
                              child: _buildChartContainer(
                                  listaTelemetrias, lote,
                                  isFullScreen: false),
                            ),
                            if (listaTelemetrias.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              _buildTechnicalDataBox(lote),
                              const SizedBox(height: 25),
                              _buildSectionTitle("HISTORIAL DE TRAZABILIDAD"),
                              _buildTimelineList(listaTelemetrias, lote),
                            ],
                            const SizedBox(height: 50),
                          ],
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
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  String _buildSubtituloFiltro() {
    final opciones = {
      "24h": "Últimas 24 horas",
      "3dias": "Últimos 3 días",
      "semana": "Última semana",
      "mes": "Último mes",
      "todo": "Todo el historial",
    };
    return opciones[_rangoSeleccionado] ?? "Historial condicionado";
  }

  // ── WIDGETS DE UI (lógica interna sin cambios) ──────────────────────────────

<<<<<<< Updated upstream
  void _inicializarEstructurasVacias() {
    if (!mounted) return;
    setState(() {
      _telemetrias = [];
      _temperaturaActual = null;
      _promedioTemperatura = null;
      _limiteMin = null;
      _limiteMax = null;
      _estadoActualServidor = "...";
      _isLoading = false;
    });
  }

  String _getOptimoRange() {
    if (_limiteMin == null || _limiteMax == null) return '...';
    return '${_limiteMin!.toStringAsFixed(0)}°C a ${_limiteMax!.toStringAsFixed(0)}°C';
  }

  String _getAdvertenciaRange() {
    if (_limiteMin == null || _limiteMax == null) return '...';
    double advMin = _limiteMin! - 3;
    double advMax = _limiteMax! + 3;
    return '${advMin.toStringAsFixed(0)}°C a ${_limiteMin!.toStringAsFixed(0)}°C y ${_limiteMax!.toStringAsFixed(0)}°C a ${advMax.toStringAsFixed(0)}°C';
  }

  String _getReviewRange() {
    if (_limiteMin == null || _limiteMax == null) return '...';
    double advMin = _limiteMin! - 3;
    double advMax = _limiteMax! + 3;
    return '< ${advMin.toStringAsFixed(0)}°C o > ${advMax.toStringAsFixed(0)}°C';
  }

  List<CartesianSeries<TelemetriaLocal, String>> _buildChartSeries() {
    if (_telemetrias.isEmpty) return [];

    return [
      LineSeries<TelemetriaLocal, String>(
        dataSource: _telemetrias,
        xValueMapper: (t, _) => DateFormat('HH:mm:ss').format(t.fechaRegistro),
        yValueMapper: (t, _) => t.temperatura,
        animationDuration: 0,
        width: 1.8,
        color: const Color(0xFF94A3B8),
        markerSettings: const MarkerSettings(
          isVisible: true,
          height: 4.5,
          width: 4.5,
          shape: DataMarkerType.circle,
          borderWidth: 1,
          borderColor: Color(0xFFCBD5E1),
        ),
        pointColorMapper: (t, _) {
          if (_limiteMin == null || _limiteMax == null) return appleBlue;
          final bool isOptimal =
              t.temperatura >= _limiteMin! && t.temperatura <= _limiteMax!;
          return isOptimal ? appleGreen : appleRed;
=======
  Widget _buildChartContainer(List<Telemetria> telemetrias, Lote lote,
      {required bool isFullScreen}) {
    if (telemetrias.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double disponibleHeight =
              MediaQuery.of(context).size.height * 0.45;
          return Container(
            height: disponibleHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sensors_off_rounded,
                      color: Color(0xFF94A3B8), size: 42),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No hay datos ingresados en este lote',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      letterSpacing: -0.3,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Deslice hacia abajo para actualizar',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      letterSpacing: -0.3,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          );
>>>>>>> Stashed changes
        },
      ),
    ];
  }

  Widget _buildChartFrame({required bool isFullScreen}) {
    if (_telemetrias.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off_rounded, color: labelGray, size: 36),
            SizedBox(height: 8),
            Text(
              'Esperando señal del sensor...',
              style: TextStyle(color: labelGray, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final allTemps = _telemetrias.map((t) => t.temperatura).toList();
    double minTemp = allTemps.reduce(min);
    double maxTemp = allTemps.reduce(max);

    if (_limiteMin != null) minTemp = min(minTemp, _limiteMin!);
    if (_limiteMax != null) maxTemp = max(maxTemp, _limiteMax!);

    final double axisMin = (minTemp - 2).floorToDouble();
    final double axisMax = (maxTemp + 2).ceilToDouble();
    const double yInterval = 2.0;

    final double bandStart = _limiteMin ?? axisMin;
    final double bandEnd = _limiteMax ?? axisMax;
    final bool hasValidBand =
        _limiteMin != null && _limiteMax != null && (bandEnd > bandStart);

    return Container(
<<<<<<< Updated upstream
      height: isFullScreen ? null : 260,
      padding: const EdgeInsets.all(4),
      child: SfCartesianChart(
        key: UniqueKey(),
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          zoomMode: ZoomMode.x,
        ),
        plotAreaBorderWidth: 0,
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          lineType: TrackballLineType.vertical,
          lineColor: appleBlue.withOpacity(0.3),
          tooltipSettings: const InteractiveTooltip(enable: false),
          builder: (BuildContext context, TrackballDetails details) {
            final double temp = (details.point?.y ?? 0.0).toDouble();
            final int index = details.pointIndex!;
            final TelemetriaLocal data = _telemetrias[index];
            final String hora = DateFormat(
              'HH:mm:ss',
            ).format(data.fechaRegistro);

            bool isOptimal = true;
            if (_limiteMin != null && _limiteMax != null) {
              isOptimal = temp >= _limiteMin! && temp <= _limiteMax!;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOptimal ? appleGreen : appleRed,
=======
      height: isFullScreen ? null : 355,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isFullScreen ? 0 : 25),
        boxShadow: isFullScreen
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFullScreen) ...[
            const Padding(
              padding: EdgeInsets.only(left: 6, top: 4, bottom: 10),
              child: Text(
                "Gráfica de Temperatura",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ],
          Expanded(
            child: SfCartesianChart(
              zoomPanBehavior:
                  ZoomPanBehavior(enablePanning: true, zoomMode: ZoomMode.x),
              plotAreaBorderWidth: 0,
              trackballBehavior: TrackballBehavior(
                enable: true,
                activationMode: ActivationMode.singleTap,
                builder: (BuildContext context, TrackballDetails details) {
                  final double temp = (details.point?.y ?? 0.0).toDouble();
                  final int index = details.pointIndex!;
                  final Telemetria data = telemetrias[index];
                  final String hora =
                      DateFormat('HH:mm:ss').format(data.fechaRegistro);
                  final bool isOptimal =
                      temp <= lote.tempMaxIdeal && temp >= lote.tempMinIdeal;
                  final Color colorBase = isOptimal
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFFEF4444);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colorBase, width: 1.5),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromARGB(255, 187, 137, 43),
                                Color(0xFF000000),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("${temp.toStringAsFixed(1)}°C   ( $hora )",
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
>>>>>>> Stashed changes
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${temp.toStringAsFixed(1)}°C  ($hora)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
<<<<<<< Updated upstream
            );
          },
        ),
        primaryXAxis: CategoryAxis(
          isVisible: true,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: const TextStyle(fontSize: 0),
          title: AxisTitle(
            text: 'ZONA ÓPTIMA ■',
            textStyle: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: appleGreen.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
          autoScrollingDelta: 5,
          autoScrollingMode: AutoScrollingMode.end,
        ),
        primaryYAxis: NumericAxis(
          minimum: axisMin,
          maximum: axisMax,
          interval: yInterval,
          labelFormat: '{value}°C',
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(
            width: 1,
            color: Color(0xFFE5E5EA),
          ),
          labelStyle: const TextStyle(
            color: labelGray,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
          plotBands: hasValidBand
              ? [
                  PlotBand(
                    start: bandStart,
                    end: bandEnd,
                    color: appleGreen.withOpacity(0.08),
                    isVisible: true,
                  ),
                ]
              : [],
        ),
        series: _buildChartSeries(),
=======
              primaryXAxis: const CategoryAxis(
                isVisible: true,
                axisLine: AxisLine(width: 0),
                majorGridLines: MajorGridLines(width: 0),
                majorTickLines: MajorTickLines(size: 0),
                labelStyle: TextStyle(fontSize: 0),
                autoScrollingDelta: 5,
                autoScrollingMode: AutoScrollingMode.end,
              ),
              primaryYAxis: NumericAxis(
                minimum: axisMin,
                maximum: axisMax,
                interval: yInterval,
                labelFormat: '{value}°C',
                axisLine: const AxisLine(width: 0),
                majorGridLines:
                    const MajorGridLines(width: 1.5, color: Color(0xFFF1F5F9)),
                labelStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
                plotBands: shouldShowBand
                    ? [
                        PlotBand(
                          start: visibleBandStart,
                          end: visibleBandEnd,
                          color: const Color.fromARGB(255, 55, 255, 0)
                              .withValues(alpha: 0.09),
                          isVisible: true,
                        ),
                      ]
                    : [],
              ),
              series: _buildProfessionalSeries(telemetrias, lote),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: Text(
              'ZONA OPTIMA  ■',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: const Color.fromARGB(255, 19, 192, 88),
                  letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 5),
        ],
>>>>>>> Stashed changes
      ),
    );
  }

<<<<<<< Updated upstream
  void _showFullScreenChart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              "ANÁLISIS TEMPERATURA",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: titleColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(child: _buildChartFrame(isFullScreen: true)),
        ),
=======
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final opciones = {
          "24h": "Últimas 24 horas",
          "3dias": "Últimos 3 días",
          "semana": "Última semana",
          "mes": "Último mes",
          "todo": "Todo el historial",
        };
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: opciones.entries.map((entry) {
                final bool esSeleccionado = _rangoSeleccionado == entry.key;
                return ListTile(
                  leading: Icon(Icons.access_time_filled_rounded,
                      color: esSeleccionado
                          ? const Color(0xFF3B82F6)
                          : Colors.white),
                  title: Text(entry.value,
                      style: TextStyle(
                        fontWeight: esSeleccionado
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: esSeleccionado
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF475569),
                        letterSpacing: -0.5,
                      )),
                  trailing: esSeleccionado
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF3B82F6))
                      : null,
                  onTap: () {
                    if (esSeleccionado) {
                      Navigator.pop(context);
                      return;
                    }
                    Navigator.pop(context);
                    setState(() {
                      _rangoSeleccionado = entry.key;
                      _loadData();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewMetricsGrid(Lote lote, List<Telemetria> telemetrias,
      double? tempActual, double? tempPromedio) {
    String estadoVisual = "Sin Datos";
    Color fondoTarjetaActual = const Color(0xFF3B82F6);

    if (telemetrias.isNotEmpty) {
      final String estadoServidor = lote.estadoActual.toUpperCase();
      if (estadoServidor == "OPTIMO" || estadoServidor == "ESPERANDO") {
        estadoVisual = "Óptimo";
        fondoTarjetaActual = const Color.fromARGB(255, 32, 212, 104);
      } else if (estadoServidor == "ALERTA") {
        estadoVisual = "Alerta";
        fondoTarjetaActual = const Color(0xFFF59E0B);
      } else if (estadoServidor == "CRITICO") {
        estadoVisual = "Crítico";
        fondoTarjetaActual = const Color(0xFFEF4444);
      }
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: fondoTarjetaActual,
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.thermostat, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text("Actual",
                        style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: -0.3,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: tempActual != null
                          ? tempActual.toStringAsFixed(1)
                          : "N/A",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: tempActual != null ? " °C" : "",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
                  ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    estadoVisual.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined,
                        color: Color(0xFF94A3B8), size: 16),
                    const SizedBox(width: 6),
                    Text("Promedio",
                        style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: tempPromedio != null
                          ? tempPromedio.toStringAsFixed(1)
                          : "N/A",
                      style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 28,
                          fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: tempPromedio != null ? " °C" : "",
                      style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
                Text(
                    _rangoSeleccionado == "24h"
                        ? "24h promedio"
                        : "Filtro: $_rangoSeleccionado",
                    style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalDataBox(Lote lote) {
    final double oMin = lote.tempMinIdeal;
    final double oMax = lote.tempMaxIdeal;
    final double optMin = min(oMin, oMax);
    final double optMax = max(oMin, oMax);
    final double alertInf1 = optMin - 3;
    final double alertInf2 = optMin;
    final double advMin = min(alertInf1, alertInf2);
    final double alertSup1 = optMax;
    final double alertSup2 = optMax + 3;
    final double advMax2 = max(alertSup1, alertSup2);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Datos técnicos",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _buildTechRow(
              "Óptimo",
              "[ ${optMin.toStringAsFixed(0)}°C a ${optMax.toStringAsFixed(0)}°C ]",
              const Color(0xFF10B981)),
          const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),
          _buildTechRow(
              "Advertencia",
              "[ < ${advMin.toStringAsFixed(0)}°C ]  o  [ > ${advMax2.toStringAsFixed(0)}°C ]",
              const Color(0xFFF59E0B)),
          const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),
          _buildTechRow(
              "Crítico",
              "[ (+) ${advMin.toStringAsFixed(0)}°C ]  o  [ (+) ${advMax2.toStringAsFixed(0)}°C ]",
              const Color(0xFFEF4444)),
        ],
>>>>>>> Stashed changes
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _buildTrazabilidadLista() {
    if (_telemetrias.isEmpty) {
=======
  Widget _buildTechRow(String label, String value, Color indicatorColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4, right: 10),
          decoration:
              BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
        ),
        SizedBox(
          width: 85,
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B))),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B))),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineList(List<Telemetria> telemetrias, Lote lote) {
    if (telemetrias.isEmpty) {
>>>>>>> Stashed changes
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
<<<<<<< Updated upstream
            Icon(Icons.cloud_done_outlined, color: labelGray, size: 32),
            SizedBox(height: 8),
            Text(
              'Sin registros históricos',
              style: TextStyle(color: labelGray, fontSize: 13),
            ),
=======
            Icon(Icons.sensors_off_rounded,
                color: Colors.grey.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 12),
            const Text("ESPERANDO SEÑAL DEL SENSOR",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1)),
>>>>>>> Stashed changes
          ],
        ),
      );
    }

<<<<<<< Updated upstream
    final listaReversada = _telemetrias.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listaReversada.length,
      itemBuilder: (context, idx) {
        final item = listaReversada[idx];
        bool fueraRango = false;
        if (_limiteMin != null && _limiteMax != null) {
          fueraRango =
              item.temperatura < _limiteMin! || item.temperatura > _limiteMax!;
        }

=======
    final reversedList = telemetrias.reversed.toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversedList.length,
      itemBuilder: (context, index) {
        final t = reversedList[index];
        final bool alert = t.temperatura > lote.tempMaxIdeal ||
            t.temperatura < lote.tempMinIdeal;
>>>>>>> Stashed changes
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: fueraRango
                  ? appleRed.withOpacity(0.2)
                  : appleGreen.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      fueraRango
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      color: fueraRango ? appleRed : appleGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${item.temperatura.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'HH:mm:ss',
                                ).format(item.fechaRegistro),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: labelGray,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Agregamos el diagnóstico real de alerts.py
                          Text(
                            item.diagnostico,
                            style: TextStyle(
                              fontSize: 11,
                              color: fueraRango
                                  ? appleRed.withOpacity(0.8)
                                  : labelGray,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.humedad.toInt()}% HR',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fueraRango ? "ANOMALÍA" : "NORMAL",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: fueraRango ? appleRed : appleGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String txtActual = _temperaturaActual != null
        ? '${_temperaturaActual!.toStringAsFixed(1)}°C'
        : '...';
    final String txtPromedio = _promedioTemperatura != null
        ? '${_promedioTemperatura!.toStringAsFixed(1)}°C'
        : '...';

    // El diagnóstico superior ahora responde al estado real procesado por el backend
    String txtEstado = "Sin datos";
    Color colorCardActual = labelGray;

    if (_temperaturaActual != null) {
      if (_estadoActualServidor.toUpperCase() == "OPTIMO") {
        txtEstado = "Óptimo";
        colorCardActual = appleGreen;
      } else if (_estadoActualServidor.toUpperCase() == "ADVERTENCIA") {
        txtEstado = "Advertencia";
        colorCardActual = appleOrange;
      } else if (_estadoActualServidor.toUpperCase() == "CRITICO") {
        txtEstado = "Crítico";
        colorCardActual = appleRed;
      } else {
        txtEstado = _estadoActualServidor;
        colorCardActual = appleBlue;
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: appleBlue))
              : RefreshIndicator(
                  color: appleBlue,
                  onRefresh: () => _fetchHistorialLote(showLoading: false),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.nombre,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.8,
                                      color: titleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Lote: ${widget.product.lote}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: labelGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: appleBlue.withOpacity(0.10),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: appleBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: '⚡ Actual',
                                value: txtActual,
                                subText: txtEstado,
                                bg: colorCardActual,
                                textColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _MetricCard(
                                title: '📈 Promedio',
                                value: txtPromedio,
                                subText: 'Histórico',
                                bg: cardColor,
                                textColor: titleColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: _telemetrias.isEmpty
                              ? null
                              : () => _showFullScreenChart(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Gráfica de Temperatura',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                      ),
                                    ),
                                    if (_telemetrias.isNotEmpty)
                                      const Icon(
                                        Icons.fullscreen_rounded,
                                        size: 20,
                                        color: labelGray,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildChartFrame(isFullScreen: false),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rangos de Temperatura',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _RangoRow(
                                color: appleGreen,
                                label: 'Óptimo',
                                range: _getOptimoRange(),
                              ),
                              const Divider(height: 20, color: bgColor),
                              _RangoRow(
                                color: appleOrange,
                                label: 'Advertencia',
                                range: _getAdvertenciaRange(),
                              ),
                              const Divider(height: 20, color: bgColor),
                              _RangoRow(
                                color: appleRed,
                                label: 'Crítico',
                                range: _getReviewRange(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 12),
                          child: Text(
                            'HISTORIAL DE TRAZABILIDAD',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: labelGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        _buildTrazabilidadLista(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subText;
  final Color bg;
  final Color textColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
<<<<<<< Updated upstream
        color: bg,
        borderRadius: BorderRadius.circular(20),
=======
          color: (alert ? const Color(0xFFEF4444) : const Color(0xFF10B981))
              .withValues(alpha: 0.1),
          shape: BoxShape.circle),
      child: Icon(alert ? Icons.warning_rounded : Icons.verified_rounded,
          color: alert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          size: 16),
    );
  }

  Widget _buildStatusLabel(bool alert, double humidity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("${humidity.toInt()}% HR",
            style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                fontSize: 11)),
        const SizedBox(height: 3),
        Text(
          alert ? "FUERA DE RANGO" : "SISTEMA ÓPTIMO",
          style: TextStyle(
              color: alert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3),
        ),
      ],
    );
  }

  void _showFullScreenChart(
      BuildContext context, List<Telemetria> telemetrias, Lote lote) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text("CONTROL TERMICO",
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A))),
          leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context)),
        ),
        body: _buildChartContainer(telemetrias, lote, isFullScreen: true),
>>>>>>> Stashed changes
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< Updated upstream
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.9)),
          ),
=======
          const Icon(Icons.cloud_off_rounded,
              color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 20),
          Text("ERROR DE SINCRONIZACIÓN",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)),
          TextButton(
              onPressed: () => setState(() => _loadData()),
              child: const Text("REINTENTAR")),
>>>>>>> Stashed changes
        ],
      ),
    );
  }
}

class _RangoRow extends StatelessWidget {
  final Color color;
  final String label;
  final String range;

  const _RangoRow({
    required this.color,
    required this.label,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
          ],
        ),
        Expanded(
          child: Text(
            range,
            style: const TextStyle(
              fontSize: 12,
              color: labelGray,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
