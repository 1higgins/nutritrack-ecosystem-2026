import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Crucial para detectar Chrome
import 'package:http/http.dart' as http;
import '../models/lote_model.dart';

/// Excepciones personalizadas con trazabilidad de errores.
class LoteServiceException implements Exception {
  final String message;
  final int? statusCode;
  LoteServiceException(this.message, [this.statusCode]);
  @override
  String toString() => "LoteServiceException: $message (Code: $statusCode)";
}

/// SERVICIO DE GRADO INDUSTRIAL: Gestión de Telemetría y Logística.
class LoteService {
  static final LoteService _instance = LoteService._internal();
  factory LoteService() => _instance;
  LoteService._internal();

  /// RESOLUCIÓN DINÁMICA DE ENDPOINT:
  /// Detecta si es Web (Chrome) o Móvil (Emulador/Físico)
  static String get _baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000"; // Para Chrome
    } else {
      // Para Android Emulator. Si es dispositivo físico, usar IP local (ej. 192.168.1.10)
      return "http://10.0.2.2:8000";
    }
  }

  static const int _maxRetries = 2;

  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        // Evita problemas de caché en navegadores
        'Cache-Control': 'no-cache',
      };

  /// Obtiene la colección completa de lotes.
  Future<List<Lote>> fetchLotes(String token) async {
    return _retryOnFailure(() async {
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/lotes/'), headers: _getHeaders(token))
            .timeout(const Duration(seconds: 15));

        return _processResponse<List<Lote>>(response, (body) {
          final List<dynamic> data = json.decode(body);
          return data.map((item) => Lote.fromJson(item)).toList();
        });
      } on SocketException {
        throw LoteServiceException('Error de red: Servidor inaccesible.');
      } on TimeoutException {
        throw LoteServiceException('Timeout: El servidor no responde.');
      } catch (e) {
        throw LoteServiceException('Error inesperado: $e');
      }
    });
  }

  // Añade este método dentro de la clase LoteService en lote_service.dart

  /// PROTOCOLO DE CIERRE (OPT/ADMIN): Finaliza la custodia del lote.
  /// Implementa el Handshake Triple: nombre_opa, codigo_lote, password_lote.
  /// PROTOCOLO DE CIERRE (OPT/ADMIN): Finaliza la custodia del lote.
  /// Requiere: nombre_opa, codigo_lote, password_lote.
  Future<Lote> entregarLote(
      String token, Map<String, dynamic> entregaData) async {
    return _retryOnFailure(() async {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/lotes/entregar'),
              headers: _getHeaders(token),
              body: json.encode(entregaData),
            )
            .timeout(const Duration(seconds: 15));

        return _processResponse<Lote>(response, (body) {
          return Lote.fromJson(json.decode(body));
        });
      } on SocketException {
        throw LoteServiceException(
            'Error de red: Servidor de entrega no alcanzado.');
      } catch (e) {
        if (e is LoteServiceException) rethrow;
        throw LoteServiceException('Fallo en el protocolo de cierre: $e');
      }
    });
  }

  /// Recupera el detalle forense de un lote específico.
  Future<Lote> fetchLoteDetail(String token, int loteId) async {
    return _retryOnFailure(() async {
      try {
        final response = await http
            .get(
              Uri.parse('$_baseUrl/lotes/$loteId'),
              headers: _getHeaders(token),
            )
            .timeout(const Duration(seconds: 12));

        return _processResponse<Lote>(response, (body) {
          return Lote.fromJson(json.decode(body));
        });
      } catch (e) {
        rethrow;
      }
    });
  }

  /// REGISTRO LOGÍSTICO (OPA): Crea un nuevo activo en el ecosistema.
  Future<Lote> createLote(String token, Map<String, dynamic> loteData) async {
    return _retryOnFailure(() async {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/lotes/'),
              headers: _getHeaders(token),
              body: json.encode(loteData),
            )
            .timeout(const Duration(seconds: 15));

        return _processResponse<Lote>(response, (body) {
          return Lote.fromJson(json.decode(body));
        });
      } on SocketException {
        throw LoteServiceException('Error de conexión al crear lote.');
      } catch (e) {
        if (e is LoteServiceException) rethrow;
        throw LoteServiceException('Error al registrar lote: $e');
      }
    });
  }

  /// PROTOCOLO DE VINCULACIÓN (OPT): El transportista reclama la custodia.
  Future<Lote> vincularLote(
      String token, Map<String, dynamic> vinculoData) async {
    return _retryOnFailure(() async {
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/lotes/vincular'),
              headers: _getHeaders(token),
              body: json.encode(vinculoData),
            )
            .timeout(const Duration(seconds: 15));

        return _processResponse<Lote>(response, (body) {
          return Lote.fromJson(json.decode(body));
        });
      } on SocketException {
        throw LoteServiceException('Error de conexión en el vínculo.');
      } catch (e) {
        if (e is LoteServiceException) rethrow;
        throw LoteServiceException('Error de validación en vínculo: $e');
      }
    });
  }

  /// PROCESADOR CORE: Estandarización de respuestas HTTP.
  T _processResponse<T>(
    http.Response response,
    T Function(String body) mapper,
  ) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return mapper(response.body);
      case 401:
        throw LoteServiceException('Sesión expirada.', 401);
      case 403:
        throw LoteServiceException('Acceso denegado.', 403);
      case 404:
        throw LoteServiceException('Recurso no encontrado.', 404);
      case 500:
        throw LoteServiceException('Fallo interno del servidor.', 500);
      default:
        throw LoteServiceException('Error inesperado.', response.statusCode);
    }
  }

  /// MÉTODO WRAPPER: Reintentos progresivos.
  Future<T> _retryOnFailure<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        // En Web, SocketException se manifiesta distinto; este catch maneja ambos
        if (attempts > _maxRetries || e is LoteServiceException) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }
}
