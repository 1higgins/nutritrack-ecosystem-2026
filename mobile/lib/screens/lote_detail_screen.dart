import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
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
  List<TelemetriaLocal> _telemetrias = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  int? _idLoteReal;
  double? _limiteMin;
  double? _limiteMax;
  double? _temperaturaActual;
  double? _promedioTemperatura;
  String _estadoActualServidor = "...";

  @override
  void initState() {
    super.initState();
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
    }
  }

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
      ),
    );
  }

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
      ),
    );
  }

  Widget _buildTrazabilidadLista() {
    if (_telemetrias.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(Icons.cloud_done_outlined, color: labelGray, size: 32),
            SizedBox(height: 8),
            Text(
              'Sin registros históricos',
              style: TextStyle(color: labelGray, fontSize: 13),
            ),
          ],
        ),
      );
    }

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
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
