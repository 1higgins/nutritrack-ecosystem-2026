import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/lote_model.dart';

class LoteServiceException implements Exception {
  final String message;
  final int? statusCode;
  LoteServiceException(this.message, [this.statusCode]);
  @override
  String toString() => "LoteServiceException: $message (Code: $statusCode)";
}

class LoteService {
  static final LoteService _instance = LoteService._internal();
  factory LoteService() => _instance;
  LoteService._internal();

  static String get _baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    } else {
      return "http://127.0.0.1:8000";
    }
  }

  static const int _maxRetries = 2;

  Map<String, String> _getHeaders(String token) => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      };

  /// OBTENCIÓN CON FILTRADO AVANZADO CRUZADO (MÓDULO AUDITORÍA)
  /// Si rangoFecha es omitido, por defecto el backend aplicará "24h".
  Future<List<Lote>> fetchLotes(
    String token, {
    String? username,
    String? rangoFecha,
  }) async {
    return _retryOnFailure(() async {
      try {
        // Construcción profesional de la Query URL usando el mapa nativo de Uri
        final Map<String, String> queryParameters = {};

        if (username != null && username.trim().isNotEmpty) {
          queryParameters['username'] = username.trim();
        }
        if (rangoFecha != null && rangoFecha.trim().isNotEmpty) {
          queryParameters['rango_fecha'] = rangoFecha.trim();
        }

        // Divide la URL base para inyectar correctamente los Query Parameters
        final baseUri = Uri.parse('$_baseUrl/lotes/');
        final finalUri = Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: baseUri.path,
          queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        );

        final response = await http
            .get(finalUri, headers: _getHeaders(token))
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
        throw LoteServiceException('Error inesperado en fetch: $e');
      }
    });
  }

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

  /// OBTENCIÓN DE AUDITORÍA TÉRMICA DETALLADA (MÓDULO GRÁFICA Y MÉTRICAS)
  /// Consume el endpoint FastAPI /lotes/{loteId} inyectando el query parameter temporal.
  Future<Map<String, dynamic>> fetchLoteDetail(
    String token,
    int loteId, {
    String? rangoFecha,
  }) async {
    return _retryOnFailure(() async {
      try {
        // 1. Construcción limpia de parámetros de consulta
        final Map<String, String> queryParameters = {};
        if (rangoFecha != null && rangoFecha.trim().isNotEmpty) {
          queryParameters['rango_fecha'] = rangoFecha.trim();
        }

        // 2. Parseo y ensamble de la URI con segmentación por Lote ID
        final baseUri = Uri.parse('$_baseUrl/lotes/$loteId');
        final finalUri = Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: baseUri.path,
          queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
        );

        // 3. Ejecución de la petición HTTP con timeout adaptado
        final response = await http
            .get(finalUri, headers: _getHeaders(token))
            .timeout(const Duration(seconds: 12));

        // 4. Procesamiento y mapeo seguro de la respuesta JSON parseada
        return _processResponse<Map<String, dynamic>>(response, (body) {
          final Map<String, dynamic> data = json.decode(body);
          return data;
        });
      } on SocketException {
        throw LoteServiceException(
            'Error de red: Servidor de detalle inaccesible.');
      } on TimeoutException {
        throw LoteServiceException(
            'Timeout: El servidor de auditoría no responde.');
      } catch (e) {
        if (e is LoteServiceException) rethrow;
        throw LoteServiceException(
            'Error inesperado al recuperar detalle de lote: $e');
      }
    });
  }

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

  T _processResponse<T>(
    http.Response response,
    T Function(String body) mapper,
  ) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return mapper(response.body);
      case 400:
        String mensaje = 'Datos de solicitud inválidos.';
        try {
          final Map<String, dynamic> errorJson = json.decode(response.body);
          mensaje = errorJson['error'] ?? errorJson['detail'] ?? mensaje;
        } catch (_) {}
        throw LoteServiceException(mensaje, 400);
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

  Future<T> _retryOnFailure<T>(Future<T> Function() action) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await action();
      } catch (e) {
        if (attempts > _maxRetries || e is LoteServiceException) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
  }
}
