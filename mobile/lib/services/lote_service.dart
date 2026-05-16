import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LoteService {
  // Ajusta esta IP si usas emulador Android (10.0.2.2) o dispositivo real
  final String baseUrl = "http://127.0.0.1:8000";

  /// Registra un nuevo lote en el ecosistema NutriTrack.
  /// Requiere el [token] obtenido en el Login para la política de seguridad OPA.
  Future<bool> registrarLote({
    required String token,
    required String codigoLote,
    required String producto,
    required double tempMinIdeal,
    required double tempMaxIdeal,
    required int cantidad,
    required String passwordLote,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/lotes/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization':
                  'Bearer $token', // Token JWT para autenticación en FastAPI
            },
            body: jsonEncode({
              'codigo_lote': codigoLote,
              'producto': producto,
              'temp_min_ideal': tempMinIdeal,
              'temp_max_ideal': tempMaxIdeal,
              'cantidad': cantidad,
              'password_lote': passwordLote,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        debugPrint(
          "Lote [$codigoLote] registrado exitosamente en la base de datos.",
        );
        return true;
      } else {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        final String errorDetail = errorBody['detail'] ?? "Error desconocido";
        debugPrint(
          "Fallo al registrar lote (${response.statusCode}): $errorDetail",
        );
        return false;
      }
    } on SocketException {
      debugPrint("Error de red: No se pudo conectar al servidor.");
      return false;
    } catch (e) {
      debugPrint("Excepción inesperada en LoteService: $e");
      return false;
    }
  }
}
