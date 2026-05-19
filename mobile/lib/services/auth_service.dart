import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 📍 IMPORTANTE: Añadir esta dependencia

class NutriTrackException implements Exception {
  final String message;
  NutriTrackException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final String role;
  AuthResult({required this.token, required this.role});
}

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000";

  // Constantes internas para evitar errores de tipeo al guardar/borrar
  static const String _keyToken = "access_token";
  static const String _keyRole = "user_role";

  /// Lógica profesional: Devuelve AuthResult y PERSISTE los datos en el dispositivo.
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

        final String token = data['access_token'];
        final String role = data['role'] ?? 'user';

        // 📍 INYECCIÓN DE PERSISTENCIA: Guardamos el token y el rol de forma física
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keyRole, role);

        debugPrint(
            "🔐 Autenticación Exitosa y Persistida para: $username [Rol: $role]");
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

  // ==========================================================================
  // 📍 NUEVO MÉTODO: LOGOUT (El encargado de limpiar la sesión al presionar [->)
  // ==========================================================================
  /// Elimina por completo los datos de sesión almacenados en el dispositivo.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    debugPrint("🚪 Sesión destruida localmente en el dispositivo.");
  }

  // ==========================================================================
  // 📍 NUEVO MÉTODO: VERIFICAR TOKEN (Útil para saber si hay una sesión activa)
  // ==========================================================================
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }
}
