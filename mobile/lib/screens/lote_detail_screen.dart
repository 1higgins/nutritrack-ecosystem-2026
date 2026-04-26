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

  late Future<Lote> _loteFuture;

  @override
  void initState() {
    super.initState();

    _loadData(); // Dispara la petición al API al iniciar
  }

  void _loadData() {
    _loteFuture = _loteService.fetchLoteDetail(widget.token, widget.loteId);
  }

  // ==========================================================================

  // MOTOR DE RENDERIZADO DEL GRÁFICO (LÓGICA DE SERIES)

  // ==========================================================================

  List<CartesianSeries<Telemetria, String>> _buildProfessionalSeries(
      Lote lote, bool isFullScreen) {
    List<CartesianSeries<Telemetria, String>> series = [];

    if (lote.telemetrias.isEmpty) return series;

    // Ordenar para asegurar continuidad cronológica
    final data = List<Telemetria>.from(lote.telemetrias)
      ..sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));

    series.add(LineSeries<Telemetria, String>(
      dataSource: data,
      xValueMapper: (t, _) => DateFormat('HH:mm:ss').format(t.fechaRegistro),
      yValueMapper: (t, _) => t.temperatura,

      // --- ESTILO "BOLSA DE VALORES" (RECTO) ---
      animationDuration:
          0, // CRÍTICO: Elimina el efecto elástico/suavizado al cargar
      width: 1.5, // grosor de linea
      color:
          const Color.fromARGB(255, 165, 178, 190), //cambia color de la linea

      // Configuración de los puntos (nodos)
      markerSettings: const MarkerSettings(
        isVisible: true, //true muestra puntos
        height: 3.5,
        width: 3.5,
        shape: DataMarkerType.circle,
        borderWidth: 1,
        borderColor: Color.fromARGB(255, 173, 175, 176),
      ),

      // Mantenemos tu lógica de colores para los puntos
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(context),
      body: FutureBuilder<Lote>(
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

          final lote = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadData()),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  _buildHeaderInfo(lote), // Código del Lote y Producto

                  const SizedBox(height: 25),

                  _buildMetricsRow(
                      lote), // Los 3 cuadros superiores (Min, Estado, Max)

                  const SizedBox(height: 30),

                  // CONTENEDOR DEL GRÁFICO REDUCIDO

                  GestureDetector(
                    onTap: () => _showFullScreenChart(
                        context, lote), // Abre la pantalla completa

                    child: _buildChartContainer(lote, isFullScreen: false),
                  ),

                  const SizedBox(height: 35),

                  _buildSectionTitle("HISTORIAL DE TRAZABILIDAD"),

                  _buildTimelineList(lote), // Lista de lecturas inferiores

                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  double getVisibleTopLimit(
    double axisMin,
    double axisMax,
    double interval,
    double idealMax,
  ) {
    List<double> visibleLabels = [];

    for (double v = axisMin; v <= axisMax; v += interval) {
      visibleLabels.add(v);
    }

    double lastVisible = visibleLabels.last;

    // Si el límite máximo ideal entra en el eje visible
    if (idealMax <= lastVisible) {
      return idealMax;
    }

    // Si NO entra, usamos el último valor visible
    return lastVisible;
  }
  // CONFIGURACIÓN DEL FRAME DEL GRÁFICO (Ejes, Trackball, Sombras)

  // ==========================================================================

  Widget _buildChartContainer(Lote lote, {required bool isFullScreen}) {
    final allTemps = lote.telemetrias.map((t) => t.temperatura).toList();

    final double rawMin = (allTemps.isEmpty ? -20 : allTemps.reduce(min)) - 2;
    final double rawMax = (allTemps.isEmpty ? 0 : allTemps.reduce(max)) + 2;
    final double axisMin = rawMin.floorToDouble();
    final double axisMax = rawMax.ceilToDouble();

    const double yInterval = 2.0;

    final double visibleTopForBand = getVisibleTopLimit(
      axisMin,
      axisMax,
      yInterval,
      lote.tempMaxIdeal,
    );

    final double visibleBandStart = max(lote.tempMinIdeal, axisMin);

    final double visibleBandEnd = visibleTopForBand;

// SOLO mostramos el verde si existe un área REAL visible
    final bool shouldShowBand = visibleBandEnd > visibleBandStart;
    // 1. ELIMINAMOS la lógica de initialVisibleMin que causaba el conflicto
    // No es necesaria si usamos autoScrollingDelta correctamente.

    return Container(
      height: isFullScreen ? null : 340,
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
      padding: const EdgeInsets.all(12),
      child: SfCartesianChart(
        zoomPanBehavior: ZoomPanBehavior(
          enablePanning: true,
          zoomMode: ZoomMode.x,
        ),
        plotAreaBorderWidth: 0,
        title: ChartTitle(
            text: isFullScreen ? "" : "VISTA ANALITICA",
            textStyle: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF94A3B8),
                letterSpacing: 1)),

        // 2. CORRECCIÓN DEL TRACKBALL: El builder va FUERA de tooltipSettings
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          // builder movido aquí para que funcione correctamente
          builder: (BuildContext context, TrackballDetails details) {
            // Solución al error de num? mediante .toDouble()
            final double temp = (details.point?.y ?? 0.0).toDouble();
            final int index = details.pointIndex!;
            final Telemetria data = lote.telemetrias[index];
            final String hora =
                DateFormat('HH:mm:ss').format(data.fechaRegistro);
            final bool isOptimal =
                temp <= lote.tempMaxIdeal && temp >= lote.tempMinIdeal;
            final Color colorBase = isOptimal
                ? const Color.fromARGB(255, 1, 204, 255)
                : const Color(0xFFEF4444);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromARGB(255, 193, 146, 52),
                          Color.fromARGB(255, 0, 0, 0),
                        ],
                      ),
                      border: Border.all(color: colorBase, width: 1.5),
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
          tooltipSettings: const InteractiveTooltip(
              enable: false), // Solo el builder maneja el diseño
          lineType: TrackballLineType.vertical,
          lineColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),

        primaryXAxis: CategoryAxis(
          isVisible: true,
          axisLine: const AxisLine(width: 0), // Oculta la línea base
          majorGridLines:
              const MajorGridLines(width: 0), // Quita las líneas verticales
          majorTickLines:
              const MajorTickLines(size: 0), // Quita las rayitas de los números

          // Ocultamos los números (horas) dándoles un tamaño de 0
          labelStyle: const TextStyle(fontSize: 0),

          // Ponemos el texto de "ZONA ÓPTIMA" justo aquí
          title: AxisTitle(
            text: 'ZONA OPTIMA  ■',
            textStyle: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color:
                  const Color.fromARGB(255, 19, 192, 88), // El verde de éxito
              letterSpacing: 1.5,
            ),
          ),
          autoScrollingDelta: 3,
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

        series: _buildProfessionalSeries(lote, isFullScreen),
      ),
    );
  }

  // ==========================================================================

  // UI - COMPONENTES VISUALES SECUNDARIOS

  // ==========================================================================

  // AppBar: Título y botón de retroceso

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("CENTRO DE CONTROL",
          style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 2.0)),
    );
  }

  // Header: El número grande (Código de Lote) y el nombre del producto

  Widget _buildHeaderInfo(Lote lote) {
    return Column(
      children: [
        Text(lote.codigoLote,
            style: GoogleFonts.robotoMono(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
                letterSpacing: -1)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Text(lote.producto.toUpperCase(),
              style: GoogleFonts.inter(
                  color: const Color(0xFF2563EB),
                  letterSpacing: 1.5,
                  fontSize: 10,
                  fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  // Fila de Tarjetas: Muestra los límites y el estado actual (CONGELADO, etc.)

  Widget _buildMetricsRow(Lote lote) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metricBox(
            "LÍMITE MIN", "${lote.tempMinIdeal}°C", const Color(0xFF3B82F6)),
        _metricBox("ESTADO", lote.estadoActual, lote.colorEstado),
        _metricBox(
            "LÍMITE MAX", "${lote.tempMaxIdeal}°C", const Color(0xFFEF4444)),
      ],
    );
  }

  // Estilo de cada cuadrito de métrica

  Widget _metricBox(String title, String val, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 8,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(val,
              style: GoogleFonts.orbitron(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Lista de Trazabilidad: El historial que aparece debajo del gráfico

  Widget _buildTimelineList(Lote lote) {
    final reversedList =
        lote.telemetrias.reversed.toList(); // Lo último primero

    return ListView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // El scroll lo maneja el padre
      itemCount: reversedList.length,
      itemBuilder: (context, index) {
        final t = reversedList[index];

        // Lógica de Alerta: Decide si el item se ve rojo o verde
        final bool alert = t.temperatura > lote.tempMaxIdeal ||
            t.temperatura < lote.tempMinIdeal;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),

            // === AQUÍ ESTÁ EL CAMBIO SOLICITADO ===
            // Eliminamos el 'null' y aplicamos borde siempre, cambiando el color
            border: Border.all(
              color: alert
                  // Color para FUERA DE RANGO (Rojo suave)
                  ? const Color(0xFFFCA5A5).withValues(alpha: 0.5)
                  // Color para SISTEMA ÓPTIMO (Verde suave, idéntico al ícono)
                  : const Color(0xFF10B981).withValues(alpha: 0.3),
              width: 1,
            ),
            // =====================================

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
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusLabel(alert, t.humedad),
            ],
          ),
        );
      },
    );
  }

  // Iconos Circulares de la lista (Check verde o Alerta roja)

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

  // Etiquetas de Humedad y Texto de Estado (SISTEMA ÓPTIMO, etc.)

  Widget _buildStatusLabel(bool alert, double humidity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text("${humidity.toInt()}% HR",
            style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                fontSize: 11)),
        Text(alert ? "FUERA DE RANGO" : "SISTEMA ÓPTIMO",
            style: TextStyle(
                color:
                    alert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                fontSize: 8,
                fontWeight: FontWeight.w900)),
      ],
    );
  }

  // PANTALLA COMPLETA DEL GRÁFICO (MODAL)

  void _showFullScreenChart(BuildContext context, Lote lote) {
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

        // Reutiliza el mismo contenedor pero con isFullScreen: true

        body: _buildChartContainer(lote, isFullScreen: true),
      ),
    ));
  }

  // Títulos de Sección con Icono

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
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

  // Pantalla de Error (Si falla el internet o el servidor)

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
