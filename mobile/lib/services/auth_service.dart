import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NutriTrackException implements Exception {
  final String message;
  NutriTrackException(this.message);

  @override
  String toString() =>
      message; // Esto hace que print(e) muestre el mensaje real
}

class AuthResult {
  final String token;
  final String role;
  AuthResult({required this.token, required this.role});
}

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000";

  /// Lógica profesional: Devuelve AuthResult manteniendo toda la trazabilidad original.
  Future<AuthResult?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extraemos ambos campos del nuevo esquema del Backend
        final String token = data['access_token'];
        final String role = data['role'] ?? 'user';

        debugPrint("🔐 Autenticación Exitosa para: $username [Rol: $role]");
        return AuthResult(token: token, role: role);
      } else if (response.statusCode == 401) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String serverMessage =
            errorData['detail'] ?? "Credenciales incorrectas";
        throw NutriTrackException(serverMessage);
      } else if (response.statusCode == 404) {
        throw NutriTrackException(
            "El servicio de autenticación no fue encontrado (404)");
      } else {
        throw NutriTrackException(
            "Error en el servidor NutriTrack (Código: ${response.statusCode})");
      }
    }
    // --- CONSERVACIÓN TOTAL DE TU MANEJO DE RED ORIGINAL ---
    on SocketException {
      debugPrint("❌ Error de red: No se encontró el servidor en $baseUrl");
      throw NutriTrackException(
          "No hay conexión con el servidor (Verifica tu red)");
    } on http.ClientException {
      debugPrint("❌ Error del cliente HTTP");
      throw NutriTrackException(
          "Error de comunicación con el servicio NutriTrack");
    } catch (e) {
      if (e is NutriTrackException) {
        debugPrint("🔐 Aviso de Autenticación: ${e.message}");
        rethrow;
      }
      debugPrint("🚨 Fallo Técnico Inesperado: $e");
      throw NutriTrackException("Error inesperado en la autenticación");
    }
  }
}
