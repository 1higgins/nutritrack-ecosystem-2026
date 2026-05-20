import 'package:flutter/material.dart';

/// Representa una lectura única de sensores con trazabilidad forense.
/// Implementado con inmutabilidad estricta para evitar bugs de estado.
@immutable
class Telemetria {
  final int id;
  final double temperatura;
  final double humedad;
  final DateTime fechaRegistro;
  final String? diagnostico;
  final int usuarioId;

  const Telemetria({
    required this.id,
    required this.temperatura,
    required this.humedad,
    required this.fechaRegistro,
    this.diagnostico,
    required this.usuarioId,
  });

  factory Telemetria.fromJson(Map<String, dynamic> json) {
    return Telemetria(
      id: json['id'] as int? ?? 0,
      temperatura: (json['temperatura'] as num?)?.toDouble() ?? 0.0,
      humedad: (json['humedad'] as num?)?.toDouble() ?? 0.0,
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro']).toLocal()
          : DateTime.now(),
      diagnostico: json['diagnostico'] as String?,
      usuarioId: json['usuario_id'] as int? ?? 0,
    );
  }
}

/// Modelo de Lote con lógica de análisis industrial integrada.
@immutable
class Lote {
  final int id;
  final String codigoLote;
  final String producto;
  final double tempMinIdeal;
  final double tempMaxIdeal;
  final String estadoActual;
  final bool entregado;
  final DateTime
      fechaCreacion; // 👈 NUEVO CAMPO: Captura el TIMESTAMP histórico del backend

  // --- CAMPOS PARA VINCULACIÓN ---
  final int creadorId;
  final String? creadorUsername;
  final int? custodioId;
  final String? custodioUsername;
  final double? ultimaTemperatura;

  final List<Telemetria> telemetrias;

  const Lote({
    required this.id,
    required this.codigoLote,
    required this.producto,
    required this.tempMinIdeal,
    required this.tempMaxIdeal,
    required this.estadoActual,
    required this.entregado,
    required this.fechaCreacion, // Inyectado de manera obligatoria en el constructor
    required this.creadorId,
    this.creadorUsername,
    this.custodioId,
    this.custodioUsername,
    this.ultimaTemperatura,
    this.telemetrias = const [],
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      id: json['id'] as int? ?? 0,
      codigoLote: json['codigo_lote'] as String? ?? "N/A",
      producto: json['producto'] as String? ?? "DESCONOCIDO",
      tempMinIdeal: (json['temp_min_ideal'] as num?)?.toDouble() ?? 0.0,
      tempMaxIdeal: (json['temp_max_ideal'] as num?)?.toDouble() ?? 0.0,
      estadoActual: (json['estado_actual'] as String? ?? "ESPERANDO")
          .toUpperCase()
          .replaceAll('Ó', 'O')
          .replaceAll('Í', 'I')
          .replaceAll('ADVERTENCIA', 'ALERTA')
          .trim(),
      entregado: json['entregado'] as bool? ?? false,
      // Mapeo seguro para la fecha de creación del lote
      // Mapeo ultra-seguro tolerante a esquemas parciales (como LoteRead de FastAPI)
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion']).toLocal()
          : DateTime
              .now(), // Fallback automático si el esquema del backend omite el timestamp
      creadorId: json['creador_id'] as int? ?? 0,
      creadorUsername: json['creador_username'] as String?,
      custodioId: json['custodio_id'] as int?,
      custodioUsername: json['custodio_username'] as String?,
      ultimaTemperatura: (json['ultima_temperatura'] as num?)?.toDouble(),
      telemetrias: json['telemetrias'] != null
          ? List<Telemetria>.from(
              (json['telemetrias'] as List).map((i) => Telemetria.fromJson(i)),
            )
          : const [],
    );
  }

  Lote copyWith({
    String? estadoActual,
    bool? entregado,
    int? custodioId,
    List<Telemetria>? telemetrias,
  }) {
    return Lote(
      id: id,
      codigoLote: codigoLote,
      producto: producto,
      tempMinIdeal: tempMinIdeal,
      tempMaxIdeal: tempMaxIdeal,
      estadoActual: estadoActual ?? this.estadoActual,
      entregado: entregado ?? this.entregado,
      fechaCreacion: fechaCreacion,
      creadorId: creadorId,
      custodioId: custodioId ?? this.custodioId,
      custodioUsername: custodioUsername,
      ultimaTemperatura: ultimaTemperatura,
      telemetrias: telemetrias ?? this.telemetrias,
    );
  }

  Color get colorEstado {
    switch (estadoActual) {
      case 'OPTIMO':
        return const Color(0xFF10B981);
      case 'ALERTA':
        return const Color(0xFFF59E0B);
      case 'CRITICO':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  double get promedioTemperatura {
    if (telemetrias.isEmpty) return 0.0;
    final total = telemetrias.map((t) => t.temperatura).reduce((a, b) => a + b);
    return total / telemetrias.length;
  }

  bool get tieneAlertas =>
      estadoActual == 'CRITICO' || estadoActual == 'ALERTA';
  bool get estaVinculado => custodioId != null;
}
