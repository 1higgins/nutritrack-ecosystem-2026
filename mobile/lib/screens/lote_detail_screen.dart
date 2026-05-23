import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  final LoteService _loteService = LoteService();

  late Future<Map<String, dynamic>> _loteFuture;
  String _rangoSeleccionado = "24h";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loteFuture = _loteService.fetchLoteDetail(
      widget.token,
      widget.loteId,
      rangoFecha: _rangoSeleccionado,
    );
  }

  // ==========================================================================
  // MOTOR DE RENDERIZADO DEL GRÁFICO (EXTRACTO COMPATIBLE CON TU BACKEND)
  // ==========================================================================
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
      backgroundColor: const Color.fromARGB(255, 248, 248, 248),
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
          if (!snapshot.hasData) return const Center(child: Text("Sin datos"));

          final Map<String, dynamic> dataRaw = snapshot.data!;

          final Map<String, dynamic> loteJson = dataRaw.containsKey('lote')
              ? dataRaw['lote'] as Map<String, dynamic>
              : dataRaw;
          final lote = Lote.fromJson(loteJson);

          final List<dynamic> lecturasRaw = dataRaw['historial_lecturas'] ?? [];
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

          // 📍 ESTRUCTURA FIJA INTEGRADA: Todo lo que esté en esta columna inicial NO se moverá nunca
          // 📍 ESTRUCTURA FIJA INTEGRADA: Todo lo que esté en esta columna inicial NO se moverá nunca
          return Column(
            children: [
              // 1. SE SUBE AL LÍMITE TOTAL SUPERIOR
              const SizedBox(height: 8),

              // 📍 ACCIÓN BAR DE PRECISIÓN (Totalmente fija arriba)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height:
                      60, // 2. SE COMPACTÓ DE 106 A 60 PARA RECUPERAR EL ESPACIO
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. FLECHA DE REGRESAR "<" (Ya eliminada por ti)

                      // 2. TEXTO "TEMPERATURA"
                      Positioned(
                        left: 0.0,
                        top: 10.0, // 3. SE SUBIÓ DE 36.0 A 10.0
                        child: _buildHeaderInfo(lote),
                      ),

                      // 3. BOTÓN AZUL DE TEMPERATURA
                      Positioned(
                        right: 135,
                        top: 9.5, // 3. SE SUBIÓ DE 39.5 A 12.0
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.thermostat,
                                color: Color.fromARGB(255, 99, 159, 255),
                                size: 20),
                            onPressed: () => _showFilterBottomSheet(context),
                          ),
                        ),
                      ),

                      Positioned(
                        left:
                            306.6, // 👈 Ajusta este número para separarlo del botón azul a tu gusto
                        top: 8.0, // Centrado armónico por su tamaño de 42
                        child: GestureDetector(
                          onTap: () {
                            // Acción funcional para regresar a la pantalla anterior (monitor_screen.dart)
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              // Fondo celeste muy suave y transparente tal cual lo pediste
                              color: const Color(0xFFE0F2FE)
                                  .withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons
                                  .home_rounded, // 👈 Ícono de inventario/cajas estilizado
                              color: Color.fromARGB(
                                  255, 79, 182, 255), // Tu turquesa estilizado
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                  height:
                      35), // Mantiene la misma distancia exacta con la cuadrícula

              // 📍 CUADRÍCULA DE MÉTRICAS COMPLETAMENTE FIJA...

              // 📍 CUADRÍCULA DE MÉTRICAS COMPLETAMENTE FIJA (Ya no se desplaza ni baila al actualizar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildNewMetricsGrid(lote, listaTelemetrias,
                    tempActualBackend, tempPromedioBackend),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // AREA DINÁMICA: Solo lo de aquí abajo tiene Scroll y activa el Refresh
              // ==========================================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => setState(() => _loadData()),
                  color: const Color(0xFF3B82F6),
                  // edgeOffset y displacement controlan que el círculo de carga salga sutilmente abajo de las tarjetas
                  edgeOffset: 0,
                  displacement: 20,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent:
                          AlwaysScrollableScrollPhysics(), // Asegura el refresh aunque falten datos
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Gráfica de temperatura
                        GestureDetector(
                          onTap: () => _showFullScreenChart(
                              context, listaTelemetrias, lote),
                          child: _buildChartContainer(listaTelemetrias, lote,
                              isFullScreen: false),
                        ),

                        // Bloques condicionales a la existencia de datos
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
          );
        },
      ),
    );
  }

  // ==========================================================================
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
    // ==========================================================================
    // 📍 SOLUCIÓN DE CENTRADO ABSOLUTO CUANDO NO HAY TELEMETRÍA
    // ==========================================================================
    if (telemetrias.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculamos dinámicamente un tamaño generoso para que el Center actúe libremente
          final double disponibleHeight =
              MediaQuery.of(context).size.height * 0.45;

          return Container(
            height: disponibleHeight,
            width: double.infinity,
            alignment:
                Alignment.center, // Fuerza el eje X e Y al centro absoluto
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centra el contenido internamente
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Envolvemos el icono en un contenedor con opacidad premium idéntico a tu AppBar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors_off_rounded,
                    color: Color(0xFF94A3B8),
                    size: 42, // Un toque más imponente y nítido
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'No hay datos ingresados en este lote',
                  style: GoogleFonts.inter(
                    color: const Color(
                        0xFF64748B), // Slate 600 para mejor contraste y lectura
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deslice hacia abajo para actualizar',
                  style: GoogleFonts.inter(
                    color:
                        const Color(0xFF94A3B8), // Subtexto de guía logística
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
    // ... Todo el resto del código del gráfico hacia abajo permanece exactamente igual.

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
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 10),
              child: Text(
                "Gráfica de Temperatura",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
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
                            border: Border.all(
                              color: colorBase,
                              width: 1.5,
                            ),
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
                    ),
                  );
                },
                tooltipSettings: const InteractiveTooltip(enable: false),
                lineType: TrackballLineType.vertical,
                lineColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              ),
              primaryXAxis: CategoryAxis(
                isVisible: true,
                axisLine: const AxisLine(width: 0),
                majorGridLines: const MajorGridLines(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: const TextStyle(fontSize: 0),
                // 📍 Se eliminó el AxisTitle interno para evitar errores con 'margin'
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

          // 📍 SOLUCIÓN CON CONSTANTES DE FLUTTER FUERA DEL GRÁFICO
          const SizedBox(
              height:
                  10), // 👈 MODIFICA ESTE NÚMERO para darle más o menos distancia de la gráfica

          Align(
            alignment: Alignment
                .center, // Centra la palabra perfectamente debajo de la cuadrícula
            child: Text(
              'ZONA OPTIMA  ■',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: const Color.fromARGB(255, 19, 192, 88),
                  letterSpacing: 1.5),
            ),
          ),
          const SizedBox(
              height:
                  5), // Pequeño aire respecto al borde inferior de la tarjeta blanca
        ],
      ),
    );
  }

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
          "todo": "Todo el historial"
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
                          : const Color(0xFF64748B)),
                  title: Text(entry.value,
                      style: GoogleFonts.inter(
                          fontWeight: esSeleccionado
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: esSeleccionado
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF475569))),
                  trailing: esSeleccionado
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF3B82F6))
                      : null,
                  onTap: () {
                    // ==========================================================================
                    // 📍 VALIDACIÓN CRÍTICA ANTI-RELOAD INNECESARIO
                    // ==========================================================================
                    if (esSeleccionado) {
                      // Si eligen lo que ya está activo, cerramos el menú y no hacemos nada más
                      Navigator.pop(context);
                      return;
                    }

                    // Si es una opción nueva, ejecutamos la lógica normal de actualización
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

  Widget _buildHeaderInfo(Lote lote) {
    // 📍 Traducimos el código técnico al texto legible para el operario
    final opcionesTexto = {
      "24h": "Últimas 24 horas",
      "3dias": "Últimos 3 días",
      "semana": "Última semana",
      "mes": "Último mes",
      "todo": "Todo el historial"
    };

    final String subtituloFiltro =
        opcionesTexto[_rangoSeleccionado] ?? "Historial condicionado";

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Temperatura",
            style: GoogleFonts.inter(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          Text(
            // 📍 Muestra dinámicamente el filtro exacto seleccionado
            "$subtituloFiltro",
            style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
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

    return Column(
      children: [
        Row(
          children: [
            // ==========================================
            // CUADRO ACTUAL (COLOR DINÁMICO)
            // ==========================================
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.43,
                height:
                    112, // 📍 SE REDUJO DE 133 A 112 PARA QUITAR EL AIRE VERTICAL
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12), // 📍 PADDING COMPACTO
                decoration: BoxDecoration(
                    color: fondoTarjetaActual,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // 📍 DISTRIBUYE MEJOR EL ESPACIO INTERNO
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.thermostat,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text("Actual",
                            style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: tempActual != null
                                ? tempActual.toStringAsFixed(1)
                                : "N/A",
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                // 📍 CAMBIADO: Antes FontWeight.bold (w700). w600 es semi-bold, más fino y estético.
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: tempActual != null ? " °C" : "",
                            style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                // 📍 LIGERAMENTE MÁS DELGADO: Pasó de w500 a w400 para acompañar la armonía del número
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        estadoVisual.toUpperCase(),
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // ==========================================
            // CUADRO PROMEDIO
            // ==========================================
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.43,
                height:
                    112, // 📍 SE REDUJO DE 131 A 112 PARA IR EN PERFECTA SIMETRÍA
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12), // 📍 PADDING COMPACTO
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 8))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment
                      .spaceBetween, // 📍 DISTRIBUYE MEJOR EL ESPACIO INTERNO
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
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: tempPromedio != null
                                ? tempPromedio.toStringAsFixed(1)
                                : "N/A",
                            style: GoogleFonts.inter(
                                color: const Color(0xFF1E293B),
                                fontSize: 28, // 📍 SE AJUSTÓ LIGERAMENTE A 28
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: tempPromedio != null ? " °C" : "",
                            style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                        _rangoSeleccionado == "24h"
                            ? "24h promedio"
                            : "Filtro: $_rangoSeleccionado",
                        style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
        // 📍 SE ELIMINÓ EL MARGIN SIZEDBOX Y LA FILA DE LOS LÍMITES VIEJOS AQUÍ
      ],
    );
  }

  Widget _buildTechnicalDataBox(Lote lote) {
    // 1. OBTENER MIN Y MAX PUROS DEL BACKEND
    final double oMin = lote.tempMinIdeal;
    final double oMax = lote.tempMaxIdeal;

    // 2. ORDENAR RANGO ÓPTIMO
    final double optMin = min(oMin, oMax);
    final double optMax = max(oMin, oMax);

    // 3. CALCULAR EXTREMOS DE ADVERTENCIA INTELIGENTE (-3 y +3)
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
          Text(
            "Datos técnicos",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // FILA ÓPTIMO
          _buildTechRow(
              "Óptimo",
              "[ ${optMin.toStringAsFixed(0)}°C a ${optMax.toStringAsFixed(0)}°C ]",
              const Color(0xFF10B981)),
          const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),

          // FILA ADVERTENCIA (Sintetizada bajo el mismo modelo de Crítico)
          _buildTechRow(
              "Advertencia",
              "[ < ${advMin.toStringAsFixed(0)}°C ]  o  [ > ${advMax2.toStringAsFixed(0)}°C ]",
              const Color(0xFFF59E0B)),
          const Divider(height: 20, color: Color(0xFFF1F5F9), thickness: 1),

          // FILA CRÍTICO
          _buildTechRow(
              "Crítico",
              "[ (+) ${advMin.toStringAsFixed(0)}°C ]  o  [ (+) ${advMax2.toStringAsFixed(0)}°C ]",
              const Color(0xFFEF4444)),
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
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B)),
          ),
        ),
        Expanded(
          // 📍 EL CAMBIO ÚNICO: Alineamos el contenido al extremo derecho del espacio disponible
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              // Usamos textAlign para asegurar un comportamiento impecable si el texto salta de línea
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineList(List<Telemetria> telemetrias, Lote lote) {
    if (telemetrias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.sensors_off_rounded,
                color: Colors.grey.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 12),
            Text("ESPERANDO SEÑAL DEL SENSOR",
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1)),
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
                width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
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
                    Text("${t.temperatura.toStringAsFixed(1)}°C",
                        style: GoogleFonts.robotoMono(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(DateFormat('HH:mm:ss').format(t.fechaRegistro),
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600)),
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
          shape: BoxShape.circle),
      child: Icon(alert ? Icons.warning_rounded : Icons.verified_rounded,
          color: alert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          size: 16),
    );
  }

  Widget _buildStatusLabel(bool alert, double humidity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize
          .min, // 📍 Asegura que la columna ocupe solo el espacio necesario
      children: [
        Text(
          "${humidity.toInt()}% HR",
          style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w800,
              fontSize: 11),
        ),

        // 📍 EL CAMBIO CLAVE: Añade este espacio para separar los textos verticalmente
        const SizedBox(height: 3),

        Text(
          alert ? "FUERA DE RANGO" : "SISTEMA ÓPTIMO",
          style: TextStyle(
              color: alert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing:
                  0.3), // 📍 Opcional: un toque sutil de espacio entre letras para legibilidad
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
      ),
    ));
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 21),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off,
              size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: Color(0xFFEF4444), size: 48),
          const SizedBox(height: 20),
          Text("ERROR DE SINCRONIZACIÓN",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)),
          TextButton(
              onPressed: () => setState(() => _loadData()),
              child: const Text("REINTENTAR"))
        ],
      ),
    );
  }
}
