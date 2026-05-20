import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class UsuariosScreen extends StatefulWidget {
  final String token; // Token del administrador logueado actualmente

  const UsuariosScreen({super.key, required this.token});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Gestión de Estados Internos
  String _selectedRole =
      "OPA"; // Valor por defecto alineado con tu Enum de Backend
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  // Roles permitidos basados estrictamente en backend/app/schemas.py (UserRole)
  final List<Map<String, String>> _roles = [
    {"value": "OPA", "label": "Operador de Origen (OPA)"},
    {"value": "OPT", "label": "Operador de Transporte (OPT)"},
    {"value": "admin", "label": "Administrador de Sistemas (Admin)"},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Ejecuta el pipeline de validaciones locales y transmisión asíncrona al Backend
  Future<void> _procesarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.registerUser(
        adminToken: widget.token,
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        setState(() {
          _successMessage =
              "Usuario '${_usernameController.text.trim()}' registrado con éxito.";
          _usernameController.clear();
          _passwordController.clear();
          _selectedRole = "OPA"; // Reset por defecto
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          "GESTIÓN DE ACCESOS",
          style: GoogleFonts.orbitron(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () =>
              FocusScope.of(context).unfocus(), // Cierra teclado al tocar fuera
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CREAR NUEVO USUARIO",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Registre las credenciales operativas del personal garantizando la segregación de funciones (RBAC).",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- BANNER DE FEEDBACK DE ERROR ---
                  if (_errorMessage != null) ...[
                    _buildFeedbackBanner(
                      message: _errorMessage!,
                      isError: true,
                      icon: Icons.error_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- BANNER DE FEEDBACK DE ÉXITO ---
                  if (_successMessage != null) ...[
                    _buildFeedbackBanner(
                      message: _successMessage!,
                      isError: false,
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- INPUT: USERNAME ---
                  _buildInputLabel("NOMBRE DE USUARIO"),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: _buildInputDecoration(
                      hint: "Ej: Carlos_2026",
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "El nombre de usuario es obligatorio.";
                      }
                      final cleaned = value.trim();
                      if (cleaned.length < 4 || cleaned.length > 20) {
                        return "Debe contener entre 4 y 20 caracteres.";
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(cleaned)) {
                        return "Solo se permiten letras, números y guiones bajos (_).";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- INPUT: PASSWORD ---
                  _buildInputLabel("CONTRASEÑA DE ACCESO"),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: _buildInputDecoration(
                      hint: "Mínimo 6 caracteres",
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "La contraseña es obligatoria.";
                      }
                      if (value.contains(' ')) {
                        return "La contraseña no puede contener espacios en blanco.";
                      }
                      if (value.trim().length < 6) {
                        return "La contraseña debe tener al menos 6 caracteres.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- INPUT: DROPDOWN SELECCIÓN DE ROL ---
                  _buildInputLabel("ASIGNACIÓN DE ROL OPERATIVO"),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.02 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: Color(0xFF64748B), size: 28),
                      // 🌟 REEMPLAZA ESTA DECORACIÓN PARA ARREGLAR EL DISEÑO:
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.badge_outlined,
                            color: Color(0xFF3B82F6), size: 20),
                        // Añadimos un pequeño espacio a la izquierda del texto
                        // para que no choque con el icono frontal
                        contentPadding: EdgeInsets.only(
                            left: 8, right: 0, top: 12, bottom: 0),
                      ),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role["value"],
                          // 🌟 SOLUCIÓN AL OVERFLOW: Envuelve el texto para que reduzca su tamaño si el dispositivo es pequeño
                          child: Text(
                            role["label"]!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _isLoading
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedRole = newValue);
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 35),

                  // --- BOTÓN PRINCIPAL DE REGISTRO ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A), // Slate 900
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _procesarRegistro,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "REGISTRAR CREDENCIALES",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES AUXILIARES DE DISEÑO ---

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF64748B), // Slate 500
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String hint,
      required IconData prefixIcon,
      Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.normal),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF3B82F6)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required String message,
    required bool isError,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withAlpha((0.3 * 255).round()), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: isError ? Colors.redAccent : const Color(0xFF065F46),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
