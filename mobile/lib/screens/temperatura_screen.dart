import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

/// Un punto de lectura del sensor
class TempReading {
  final DateTime timestamp;
  final double value;

  const TempReading({required this.timestamp, required this.value});
}

/// Rango de temperatura y su estado
enum TempStatus { optimo, advertencia, critico }

TempStatus statusForTemp(double temp) {
  if (temp < -2 || temp > 8) return TempStatus.critico;
  if (temp >= 4) return TempStatus.advertencia;
  return TempStatus.optimo;
}

Color colorForStatus(TempStatus s) {
  switch (s) {
    case TempStatus.optimo:
      return const Color(0xFF30D158);
    case TempStatus.advertencia:
      return const Color(0xFFFF9F0A);
    case TempStatus.critico:
      return const Color(0xFFFF453A);
  }
}

Color colorForTemp(double t) => colorForStatus(statusForTemp(t));

class TemperaturaPage extends StatefulWidget {
  /// Reemplazar con lecturas reales del sensor cuando esté listo
  /// Por ahora se usan datos de demo que se actualizan cada 5 segundos
  const TemperaturaPage({super.key});

  @override
  State<TemperaturaPage> createState() => _TemperaturaPageState();
}

class _TemperaturaPageState extends State<TemperaturaPage> {
  static const Color bgColor = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color titleColor = Color(0xFF1C1C1E);
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color appleBlue = Color(0xFF007AFF);
  static const Color appleGreen = Color(0xFF30D158);
  static const Color appleOrange = Color(0xFFFF9F0A);
  static const Color appleRed = Color(0xFFFF453A);

  // Estado
  List<TempReading> _readings = [];

  @override
  void initState() {
    super.initState();
    _loadDemoReadings(); //
  }

  // ── Demo: genera 24 lecturas horarias de ejemplo ──────────────────────────
  /// Cuando tengamos el endpoint del sensor, reemplazar este método por uno
  /// similar a _fetchLotesReal() en InventarioPage.
  void _loadDemoReadings() {
    final now = DateTime.now();
    final demoValues = [
      2.1,
      1.8,
      2.4,
      3.1,
      3.8,
      4.2,
      4.6,
      5.1,
      4.9,
      4.3,
      3.7,
      3.2,
      2.9,
      2.5,
      2.2,
      2.8,
      3.3,
      3.9,
      4.4,
      4.8,
      4.6,
      4.3,
      4.1,
      3.8,
    ];
    setState(() {
      _readings = List.generate(
        demoValues.length,
        (i) => TempReading(
          timestamp: now.subtract(Duration(hours: demoValues.length - 1 - i)),
          value: demoValues[i],
        ),
      );
    });
  }

  double get _currentTemp => _readings.isEmpty ? 0 : _readings.last.value;

  double get _avgTemp {
    if (_readings.isEmpty) return 0;
    final sum = _readings.fold(0.0, (acc, r) => acc + r.value);
    return sum / _readings.length;
  }

  TempStatus get _currentStatus => statusForTemp(_currentTemp);

  String _statusLabel(TempStatus s) {
    switch (s) {
      case TempStatus.optimo:
        return 'Óptimo';
      case TempStatus.advertencia:
        return 'Advertencia';
      case TempStatus.critico:
        return 'Crítico';
    }
  }

  Color _statusBgColor(TempStatus s) {
    switch (s) {
      case TempStatus.optimo:
        return const Color(0xFFEDF9F0);
      case TempStatus.advertencia:
        return const Color(0xFFFFF4E5);
      case TempStatus.critico:
        return const Color(0xFFFFF0EE);
    }
  }

  Color _statusTextColor(TempStatus s) {
    switch (s) {
      case TempStatus.optimo:
        return const Color(0xFF1A7A32);
      case TempStatus.advertencia:
        return const Color(0xFF8A5200);
      case TempStatus.critico:
        return const Color(0xFF9B1208);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: RefreshIndicator(
            color: appleBlue,
            onRefresh: () async => _loadDemoReadings(),
            child: CustomScrollView(
              slivers: [
                // Header
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
                                'Temperatura',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.4,
                                  color: titleColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Últimas 24 horas',
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
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: appleBlue.withOpacity(0.10),
                            ),
                            child: const Icon(
                              Icons.thermostat_rounded,
                              size: 18,
                              color: appleBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tarjetas Actual / Promedio
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        // Actual
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: appleBlue,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: appleBlue.withOpacity(0.30),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.thermostat_rounded,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Actual',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text.rich(
                                  TextSpan(
                                    text: _currentTemp.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -1.6,
                                      height: 1,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' °C',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Badge de estado
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _statusLabel(_currentStatus),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Promedio
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardColor,
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
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.show_chart_rounded,
                                      size: 14,
                                      color: labelGray,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Promedio',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: labelGray,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text.rich(
                                  TextSpan(
                                    text: _avgTemp.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                      letterSpacing: -1.6,
                                      height: 1,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: ' °C',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: labelGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  '24h promedio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: labelGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Gráfica
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      decoration: BoxDecoration(
                        color: cardColor,
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
                          const Text(
                            'Gráfica de Temperatura',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            child: _readings.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: appleBlue,
                                    ),
                                  )
                                : CustomPaint(
                                    size: const Size(double.infinity, 180),
                                    painter: _TempChartPainter(
                                      readings: _readings,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          // Leyenda
                          Row(
                            children: [
                              _LegendDot(color: appleGreen, label: 'Óptimo'),
                              const SizedBox(width: 16),
                              _LegendDot(
                                color: appleOrange,
                                label: 'Advertencia',
                              ),
                              const SizedBox(width: 16),
                              _LegendDot(color: appleRed, label: 'Crítico'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rangos de Temperatura
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                      decoration: BoxDecoration(
                        color: cardColor,
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
                          const Text(
                            'Rangos de Temperatura',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _RangeRow(
                            color: appleGreen,
                            label: 'Óptimo',
                            range: '-2°C a 4°C',
                            showDivider: false,
                          ),
                          _RangeRow(
                            color: appleOrange,
                            label: 'Advertencia',
                            range: '4°C a 8°C',
                          ),
                          _RangeRow(
                            color: appleRed,
                            label: 'Crítico',
                            range: '> 8°C o < -2°C',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CustomPainter: gráfica multicolor

class _TempChartPainter extends CustomPainter {
  final List<TempReading> readings;

  // Rangos visibles en el eje Y
  static const double minY = -5;
  static const double maxY = 10;

  // Padding interno
  static const double padLeft = 36;
  static const double padRight = 10;
  static const double padTop = 10;
  static const double padBottom = 28;

  const _TempChartPainter({required this.readings});

  double _tx(int i, double width) {
    final cW = width - padLeft - padRight;
    return padLeft + (i / (readings.length - 1)) * cW;
  }

  double _ty(double value, double height) {
    final cH = height - padTop - padBottom;
    return padTop + cH - ((value - minY) / (maxY - minY)) * cH;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = const Color(0xFF8E8E93).withOpacity(0.15)
      ..strokeWidth = 0.5;
    const gridValues = [-5.0, -1.0, 3.0, 7.0, 10.0];
    final labelStyle = const TextStyle(fontSize: 10, color: Color(0xFF8E8E93));

    for (final v in gridValues) {
      final y = _ty(v, h);
      canvas.drawLine(Offset(padLeft, y), Offset(w - padRight, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(text: v.toInt().toString(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 4, y - tp.height / 2));
    }

    for (int i = 0; i < readings.length; i += 4) {
      final t = readings[i].timestamp;
      final label =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = _tx(i, w) - tp.width / 2;
      tp.paint(canvas, Offset(x, h - padBottom + 6));
    }

    if (readings.length < 2) return;

    final fillPath = Path()..moveTo(_tx(0, w), _ty(readings[0].value, h));
    for (int i = 1; i < readings.length; i++) {
      fillPath.lineTo(_tx(i, w), _ty(readings[i].value, h));
    }
    fillPath.lineTo(_tx(readings.length - 1, w), _ty(minY, h));
    fillPath.lineTo(_tx(0, w), _ty(minY, h));
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF007AFF).withOpacity(0.10),
          const Color(0xFF007AFF).withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, padTop, w, h - padTop - padBottom))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Segmentos de línea multicolor
    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < readings.length - 1; i++) {
      final midTemp = (readings[i].value + readings[i + 1].value) / 2;
      linePaint.color = colorForTemp(midTemp);
      canvas.drawLine(
        Offset(_tx(i, w), _ty(readings[i].value, h)),
        Offset(_tx(i + 1, w), _ty(readings[i + 1].value, h)),
        linePaint,
      );
    }

    // Punto final (lectura actual)
    final lastX = _tx(readings.length - 1, w);
    final lastY = _ty(readings.last.value, h);
    final dotColor = colorForTemp(readings.last.value);

    canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = dotColor);
    canvas.drawCircle(
      Offset(lastX, lastY),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _TempChartPainter old) =>
      old.readings != readings;
}

// Widgets auxiliares

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

class _RangeRow extends StatelessWidget {
  final Color color;
  final String label;
  final String range;
  final bool showDivider;

  const _RangeRow({
    required this.color,
    required this.label,
    required this.range,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF2F2F7)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1C1C1E),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                range,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
