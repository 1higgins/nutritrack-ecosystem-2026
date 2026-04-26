import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../main_wrapper.dart'; // IMPORTANTE: Ahora apuntamos al Wrapper

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  bool _obscurePassword = true;

  final TextEditingController _userController = TextEditingController(text: "");
  final TextEditingController _passController = TextEditingController(text: "");

  void _handleLogin() async {
    // 1. VALIDACIÓN ESPECÍFICA DE CAMPOS (Antes del servidor) - REINTEGRADO
    String? validationMessage;

    if (_userController.text.trim().isEmpty &&
        _passController.text.trim().isEmpty) {
      validationMessage = "Debes ingresar usuario y contraseña";
    } else if (_userController.text.trim().isEmpty) {
      validationMessage = "El campo 'Usuario' no puede estar vacío";
    } else if (_passController.text.trim().isEmpty) {
      validationMessage = "El campo 'Contraseña' no puede estar vacío";
    }

    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating, // Estilo industrial moderno
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Intento de login con el servicio profesional
      // CAMBIO CLAVE: Cambiamos 'final String? token' por 'final AuthResult? result'
      final AuthResult? result = await _authService.login(
        _userController.text.trim(),
        _passController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result != null) {
        if (!mounted) return;

        // Ahora pasamos tanto el token como el rol al MainWrapper
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainWrapper(
              token: result.token,
              role: result.role, // <--- Enviamos el rol para la lógica OPA/OPT
            ),
          ),
        );
      }
    } on NutriTrackException catch (e) {
      // ... resto de tu manejo de errores igual ...
      // Captura precisa de la excepción que definimos en el Service
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Manejo de errores de sistema no controlados
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error inesperado en la aplicación"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/LOGO_NUTRITRACK.JPG',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.ac_unit,
                    size: 80,
                    color: Color(0xFF2E6CA4),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'NutriTrack',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A3B5D),
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Cadena de Frío Inteligente',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 50),
              _buildInputFrame(
                child: TextField(
                  controller: _userController,
                  style: GoogleFonts.poppins(fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "Usuario",
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Color(0xFF2E6CA4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildInputFrame(
                child: TextField(
                  controller: _passController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: "Contraseña",
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF2E6CA4),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6CA4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "INGRESAR AL SISTEMA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "v1.0.0 Enterprise",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputFrame({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
