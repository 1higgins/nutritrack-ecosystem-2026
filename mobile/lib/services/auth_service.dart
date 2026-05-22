import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NutriTrackException implements Exception {
  final String message;
  NutriTrackException(this.message);

  @override
  String toString() => message;
}

class AuthResult {
  final String token;
  final String role; // Guardará el rol homologado para la UI
  AuthResult({required this.token, required this.role});
}

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000";

  static const String _keyToken = "access_token";
  static const String _keyRole = "user_role";
  static const String _keyUsername = "user_name";

  String homologarRol(String rawRole) {
    if (rawRole.toLowerCase() == "admin") {
      return "Administrador";
    } else if (rawRole.toUpperCase() == "OPT") {
      return "Transportista";
    } else if (rawRole.toUpperCase() == "OPA") {
      return "Operario";
    }
    return rawRole; // Por si viene un valor inesperado
  }

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
        final String rawRole = data['role'] ?? 'user';
        final String uiRole = homologarRol(rawRole); // Traducido de inmediato
        final String serverUsername = data['username'] ?? username;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keyRole, uiRole); // Guardamos el rol limpio
        await prefs.setString(_keyUsername, serverUsername);

        debugPrint(
            "🔐 Autenticación Exitosa para: $serverUsername [Rol: $uiRole]");
        return AuthResult(token: token, role: uiRole);
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
    } on SocketException {
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

  Future<void> registerUser({
    required String adminToken,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $adminToken',
            },
            body: json.encode({
              'username': username,
              'password': password,
              'role': role,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 201) {
        debugPrint("👤 Usuario '$username' [$role] creado exitosamente.");
        return;
      }

      if (response.statusCode == 400 ||
          response.statusCode == 403 ||
          response.statusCode == 422) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (response.statusCode == 422 && errorData['detail'] is List) {
          throw NutriTrackException(
              "Error de formato: El usuario debe tener entre 4 y 20 caracteres alfanuméricos y la clave mínimo 6.");
        }
        final String serverMessage = errorData['detail'] ??
            "Error de validación en los datos de registro.";
        throw NutriTrackException(serverMessage);
      } else {
        throw NutriTrackException(
            "Error inesperado en el servidor de registros (Código: ${response.statusCode})");
      }
    } on SocketException {
      throw NutriTrackException("No hay conexión con el servidor logístico.");
    } on http.ClientException {
      throw NutriTrackException(
          "Error en los protocolos de comunicación de la app.");
    } catch (e) {
      if (e is NutriTrackException) rethrow;
      throw NutriTrackException(
          "Fallo interno al procesar el registro del operario.");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUsername);
    debugPrint("🚪 Sesión destruida localmente.");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }
}
