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
      // Manejo robusto de números (int o double de la API)
      temperatura: (json['temperatura'] as num?)?.toDouble() ?? 0.0,
      humedad: (json['humedad'] as num?)?.toDouble() ?? 0.0,
      // Conversión segura de fecha ISO8601
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

  // --- NUEVOS CAMPOS PARA VINCULACIÓN ---
  final int creadorId; // ID del OPA que lo registró
  final int?
      custodioId; // ID del OPT que lo vinculó (puede ser null si nadie lo ha tomado)

  final List<Telemetria> telemetrias;

  const Lote({
    required this.id,
    required this.codigoLote,
    required this.producto,
    required this.tempMinIdeal,
    required this.tempMaxIdeal,
    required this.estadoActual,
    required this.entregado,
    required this.creadorId, // Requerido por el nuevo contrato del backend
    this.custodioId, // Opcional hasta que se vincule
    this.telemetrias = const [],
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      id: json['id'] as int? ?? 0,
      codigoLote: json['codigo_lote'] as String? ?? "N/A",
      producto: json['producto'] as String? ?? "DESCONOCIDO",
      tempMinIdeal: (json['temp_min_ideal'] as num?)?.toDouble() ?? 0.0,
      tempMaxIdeal: (json['temp_max_ideal'] as num?)?.toDouble() ?? 0.0,
      estadoActual: (json['estado_actual'] as String? ?? "OPTIMO")
          .toUpperCase()
          .replaceAll('ADVERTENCIA', 'ALERTA'),
      entregado: json['entregado'] as bool? ?? false,

      // MAPEO DE NUEVOS CAMPOS (Basado en schemas.py)
      creadorId: json['creador_id'] as int? ?? 0,
      custodioId: json['custodio_id'] as int?,

      telemetrias: json['telemetrias'] != null
          ? List<Telemetria>.from(
              (json['telemetrias'] as List).map((i) => Telemetria.fromJson(i)),
            )
          : const [],
    );
  }

  /// Patrón CopyWith actualizado para incluir custodioId tras vinculación exitosa
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
      creadorId: creadorId,
      custodioId: custodioId ?? this.custodioId,
      telemetrias: telemetrias ?? this.telemetrias,
    );
  }

  /// Lógica de Colores Industrial (Diseño de Interfaz de Alta Fidelidad)
  Color get colorEstado {
    switch (estadoActual) {
      case 'OPTIMO':
        return const Color(0xFF10B981); // Emerald 500
      case 'ALERTA': // Cambio aplicado: Más corto para la UI
        return const Color(0xFFF59E0B); // Amber 500
      case 'CRITICO':
        return const Color(0xFFEF4444); // Red 500
      default:
        return const Color(0xFF94A3B8); // Slate 400
    }
  }

  /// Cálculo de promedio movible para analítica rápida
  double get promedioTemperatura {
    if (telemetrias.isEmpty) return 0.0;
    final total = telemetrias.map((t) => t.temperatura).reduce((a, b) => a + b);
    return total / telemetrias.length;
  }

  /// Indica si el lote requiere atención inmediata
  // ... (tus getters anteriores)

  /// Indica si el lote requiere atención inmediata
  bool get tieneAlertas =>
      estadoActual == 'CRITICO' || estadoActual == 'ALERTA';

  /// NUEVO: Indica si el lote ya tiene un transportista asignado
  /// Útil para que la UI sepa si mostrar el botón de vincular o no.
  bool get estaVinculado => custodioId != null;
}
