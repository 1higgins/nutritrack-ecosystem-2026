import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';

import '../models/lote_model.dart';
import '../services/lote_service.dart';

class LoteDetailScreen extends StatefulWidget {
  final String token;
  final int loteId;

  const LoteDetailScreen({
    super.key,
    required this.token,
    required this.loteId,
  });

  @override
  State<LoteDetailScreen> createState() => _LoteDetailScreenState();
}

class _LoteDetailScreenState extends State<LoteDetailScreen> {
  static const Color _bgColor = Color(0xFFF2F2F7);
  static const Color _titleColor = Color(0xFF1C1C1E);
  static const Color _labelGray = Color(0xFF8E8E93);
  static const Color _appleBlue = Color(0xFF007AFF);

  final LoteService _loteService = LoteService();
  late Future<Map<String, dynamic>> _loteFuture;
  String _rangoSeleccionado = "24h";
  Timer? _pollingTimer;

  // Variables de estado para actualización de métricas
  double? _tempActualLive;
  double? _tempPromedioLive;
  String? _estadoActualLive;
  bool _datosInicialmenteCargados = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Polling silencioso cada 13 s
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _silentRefresh();
    });
  }

  void _loadData() {
    _loteFuture = _loteService
        .fetchLoteDetail(
      widget.token,
      widget.loteId,
      rangoFecha: _rangoSeleccionado,
    )
        .then((data) {
      // Al cargar por primera vez, también poblamos las variables live
      if (mounted) {
        setState(() {
          _tempActualLive = data['temperatura_actual'] != null
              ? (data['temperatura_actual'] as num).toDouble()
              : null;
          _tempPromedioLive = data['temperatura_promedio'] != null
              ? (data['temperatura_promedio'] as num).toDouble()
              : null;
          final loteJson = data.containsKey('lote')
              ? data['lote'] as Map<String, dynamic>
              : data;
          _estadoActualLive = loteJson['estado_actual'] as String?;
          _datosInicialmenteCargados = true;
        });
      }
      return data;
    });
  }

  // Llama al backend y actualiza SOLO los números sin tocar el FutureBuilder
  Future<void> _silentRefresh() async {
    try {
      final data = await _loteService.fetchLoteDetail(
        widget.token,
        widget.loteId,
        rangoFecha: _rangoSeleccionado,
      );
      if (!mounted) return;
      setState(() {
        _tempActualLive = data['temperatura_actual'] != null
            ? (data['temperatura_actual'] as num).toDouble()
            : null;
        _tempPromedioLive = data['temperatura_promedio'] != null
            ? (data['temperatura_promedio'] as num).toDouble()
            : null;
        final loteJson = data.containsKey('lote')
            ? data['lote'] as Map<String, dynamic>
            : data;
        _estadoActualLive = loteJson['estado_actual'] as String?;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _appleBlue, strokeWidth: 2.5));
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                "Sin datos",
                style: TextStyle(
                    color: _labelGray, fontSize: 15, letterSpacing: -0.2),
              ),
            );
          }

          final Map<String, dynamic> dataRaw = snapshot.data!;
          final Map<String, dynamic> loteJson = dataRaw.containsKey('lote')
              ? dataRaw['lote'] as Map<String, dynamic>
              : dataRaw;
          final lote = Lote.fromJson(loteJson);

          final List<dynamic> lecturasRaw = dataRaw['historial_lecturas'] ?? [];
          final List<Telemetria> listaCompleta = lecturasRaw
              .map((t) => Telemetria.fromJson(t as Map<String, dynamic>))
              .toList();

          final List<Telemetria> listaTelemetrias =
              listaCompleta.reversed.take(10).toList().reversed.toList();

          // Usamos las variables live para las métricas — se actualizan sin parpadeo
          final double? tempActualBackend = _tempActualLive;
          final double? tempPromedioBackend = _tempPromedioLive;

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── HEADER ──────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título + subtítulo
                      Expanded(
                        child: _buildHeaderInfo(lote),
                      ),
                      const SizedBox(width: 12),
                      // Botón filtro de rango
                      GestureDetector(
                        onTap: () => _showFilterBottomSheet(context),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: _appleBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.thermostat,
                            color: _appleBlue,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botón home
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE0F2FE).withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home_rounded,
                            color: Color.fromARGB(255, 79, 182, 255),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── MÉTRICAS ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildNewMetricsGrid(lote, listaTelemetrias,
                      tempActualBackend, tempPromedioBackend),
                ),

                const SizedBox(height: 22),

                // ── ÁREA SCROLLABLE ─────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => setState(() => _loadData()),
                    color: _appleBlue,
                    edgeOffset: 0,
                    displacement: 20,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullScreenChart(
                                context, listaTelemetrias, lote),
                            child: _buildChartContainer(listaTelemetrias, lote,
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
    );
  }

  // ── HEADER INFO ─────────────────────────────────────────────────────────────
  Widget _buildHeaderInfo(Lote lote) {
    final opcionesTexto = {
      "24h": "Últimas 24 horas",
      "3dias": "Últimos 3 días",
      "semana": "Última semana",
      "mes": "Último mes",
      "todo": "Todo el historial",
    };
    final String subtituloFiltro =
        opcionesTexto[_rangoSeleccionado] ?? "Historial condicionado";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Temperatura",
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w700,
            color: _titleColor,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtituloFiltro,
          style: const TextStyle(
            fontSize: 14,
            color: _labelGray,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ── MÉTRICAS GRID ───────────────────────────────────────────────────────────
  Widget _buildNewMetricsGrid(Lote lote, List<Telemetria> telemetrias,
      double? tempActual, double? tempPromedio) {
    String estadoVisual = "Sin Datos";
    Color fondoTarjetaActual = _appleBlue;

    // Usamos _estadoActualLive para que el color cambie en tiempo real sin reload
    final String estadoFuente =
        (_estadoActualLive ?? lote.estadoActual).toUpperCase();

    if (telemetrias.isNotEmpty || _datosInicialmenteCargados) {
      if (estadoFuente == "OPTIMO" || estadoFuente == "ESPERANDO") {
        estadoVisual = "Óptimo";
        fondoTarjetaActual = const Color(0xFF22C55E);
      } else if (estadoFuente == "ALERTA") {
        estadoVisual = "Alerta";
        fondoTarjetaActual = const Color(0xFFF59E0B);
      } else if (estadoFuente == "CRITICO") {
        estadoVisual = "Crítico";
        fondoTarjetaActual = const Color(0xFFEF4444);
      }
    }

    return Row(
      children: [
        // Tarjeta Actual (color dinámico)
        Expanded(
          child: Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: fondoTarjetaActual,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: fondoTarjetaActual.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.thermostat, color: Colors.white70, size: 15),
                    SizedBox(width: 4),
                    Text(
                      "Actual",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: tempActual != null
                            ? tempActual.toStringAsFixed(1)
                            : "N/A",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      TextSpan(
                        text: tempActual != null ? " °C" : "",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estadoVisual.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Tarjeta Promedio (blanca)
        Expanded(
          child: Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: _labelGray, size: 15),
                    SizedBox(width: 6),
                    Text(
                      "Promedio",
                      style: TextStyle(
                        color: _labelGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: tempPromedio != null
                            ? tempPromedio.toStringAsFixed(1)
                            : "N/A",
                        style: const TextStyle(
                          color: _titleColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      TextSpan(
                        text: tempPromedio != null ? " °C" : "",
                        style: const TextStyle(
                          color: _labelGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _rangoSeleccionado == "24h"
                      ? "24h promedio"
                      : "Filtro: $_rangoSeleccionado",
                  style: const TextStyle(
                    color: _labelGray,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── CHART ───────────────────────────────────────────────────────────────────
  double getVisibleTopLimit(
      double axisMin, double axisMax, double interval, double idealMax) {
    List<double> visibleLabels = [];
    for (double v = axisMin; v <= axisMax; v += interval) {
      visibleLabels.add(v);
    }
    double lastVisible = visibleLabels.last;
    if (idealMax <= lastVisible) return idealMax;
    return lastVisible;
  }

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
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _labelGray.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_off_rounded,
                    color: _labelGray,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No hay datos ingresados en este lote',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Deslice hacia abajo para actualizar',
                  style: TextStyle(
                    color: _labelGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final allTemps = telemetrias.map((t) => t.temperatura).toList();
    final double rawMin = allTemps.reduce(min) - 2;
    final double rawMax = allTemps.reduce(max) + 2;
    final double axisMin = rawMin.floorToDouble();
    final double axisMax = rawMax.ceilToDouble();
    const double yInterval = 2.0;

    final double visibleTopForBand =
        getVisibleTopLimit(axisMin, axisMax, yInterval, lote.tempMaxIdeal);
    final double visibleBandStart = max(lote.tempMinIdeal, axisMin);
    final double visibleBandEnd = visibleTopForBand;
    final bool shouldShowBand = visibleBandEnd > visibleBandStart;

    return Container(
      height: isFullScreen ? null : 355,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isFullScreen ? 0 : 24),
        boxShadow: isFullScreen
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFullScreen) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 2, bottom: 10),
              child: Text(
                "Gráfica de Temperatura",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _titleColor,
                  letterSpacing: -0.4,
                ),
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
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
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
                        Text(
                          "${temp.toStringAsFixed(1)}°C   ( $hora )",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                tooltipSettings: const InteractiveTooltip(enable: false),
                lineType: TrackballLineType.vertical,
                lineColor: _appleBlue.withValues(alpha: 0.3),
              ),
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
                labelStyle: const TextStyle(
                  color: _labelGray,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
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
          const Align(
            alignment: Alignment.center,
            child: Text(
              'ZONA ÓPTIMA  ■',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color.fromARGB(255, 19, 192, 88),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  // ── FILTER BOTTOM SHEET ─────────────────────────────────────────────────────
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ...opciones.entries.map((entry) {
                  final bool esSeleccionado = _rangoSeleccionado == entry.key;
                  return ListTile(
                    leading: Icon(
                      Icons.access_time_filled_rounded,
                      color: esSeleccionado ? _appleBlue : _labelGray,
                    ),
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight:
                            esSeleccionado ? FontWeight.w700 : FontWeight.w400,
                        color: esSeleccionado
                            ? _titleColor
                            : const Color(0xFF475569),
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    trailing: esSeleccionado
                        ? const Icon(Icons.check_circle_rounded,
                            color: _appleBlue)
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
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TECHNICAL DATA BOX ──────────────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Datos técnicos",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _titleColor,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildTechRow(
            "Óptimo",
            "[ ${optMin.toStringAsFixed(0)}°C a ${optMax.toStringAsFixed(0)}°C ]",
            const Color(0xFF10B981),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),
          _buildTechRow(
            "Advertencia",
            "[ < ${advMin.toStringAsFixed(0)}°C ]  o  [ > ${advMax2.toStringAsFixed(0)}°C ]",
            const Color(0xFFF59E0B),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),
          _buildTechRow(
            "Crítico",
            "[ (+) ${advMin.toStringAsFixed(0)}°C ]  o  [ (+) ${advMax2.toStringAsFixed(0)}°C ]",
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

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
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 0, 0, 0),
              letterSpacing: -0.3,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 0, 0, 0),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── TIMELINE ────────────────────────────────────────────────────────────────
  Widget _buildTimelineList(List<Telemetria> telemetrias, Lote lote) {
    if (telemetrias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.sensors_off_rounded,
                color: _labelGray.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 12),
            const Text(
              "ESPERANDO SEÑAL DEL SENSOR",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _labelGray,
                  letterSpacing: -0.3),
            ),
          ],
        ),
      );
    }

    final reversedList = telemetrias.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reversedList.length,
      itemBuilder: (context, index) {
        final t = reversedList[index];
        final bool alert = t.temperatura > lote.tempMaxIdeal ||
            t.temperatura < lote.tempMinIdeal;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: alert
                  ? const Color(0xFFFCA5A5).withValues(alpha: 0.5)
                  : const Color(0xFF10B981).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildAlertIcon(alert),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${t.temperatura.toStringAsFixed(1)}°C",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _titleColor,
                        letterSpacing: -0.3,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm:ss').format(t.fechaRegistro),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _labelGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusLabel(alert, t.humedad),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertIcon(bool alert) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (alert ? const Color(0xFFEF4444) : const Color(0xFF10B981))
            .withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        alert ? Icons.warning_rounded : Icons.verified_rounded,
        color: alert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        size: 16,
      ),
    );
  }

  Widget _buildStatusLabel(bool alert, double humidity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${humidity.toInt()}% HR",
          style: const TextStyle(
            color: _labelGray,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          alert ? "FUERA DE RANGO" : "SISTEMA ÓPTIMO",
          style: TextStyle(
            color: alert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── FULL SCREEN CHART ───────────────────────────────────────────────────────
  void _showFullScreenChart(
      BuildContext context, List<Telemetria> telemetrias, Lote lote) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "CONTROL TÉRMICO",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _titleColor,
              letterSpacing: 0.5,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildChartContainer(telemetrias, lote, isFullScreen: true),
      ),
    ));
  }

  // ── TITULO ───────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 21),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, size: 14, color: _labelGray),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: _labelGray,
            ),
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ─────────────────────────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 20),
          const Text(
            "Error de sincronización",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: _titleColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _loadData()),
            child: const Text(
              "Reintentar",
              style: TextStyle(
                color: _appleBlue,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
