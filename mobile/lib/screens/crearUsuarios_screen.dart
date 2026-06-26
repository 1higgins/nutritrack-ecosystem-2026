import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class UsuariosScreen extends StatefulWidget {
  final String token;

  const UsuariosScreen({super.key, required this.token});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  // Colores estilo iOS
  static const Color _bgColor = Color(0xFFF2F2F7);
  static const Color _cardColor = Colors.white;
  static const Color _titleColor = Color(0xFF1C1C1E);
  static const Color _labelGray = Color(0xFF8E8E93);
  static const Color _appleBlue = Color(0xFF007AFF);

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controladores — sin cambios de lógica
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = "OPA";
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

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

  // ── LÓGICA SIN CAMBIOS ──────────────────────────────────────────────────────
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
          _selectedRole = "OPA";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // ── FIN LÓGICA ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: CustomScrollView(
              slivers: [
                // ── ENCABEZADO
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Crear Usuario',
                                    style: TextStyle(
                                      fontSize: 31,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -1.4,
                                      color: _titleColor,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      height: 42,
                                      width: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE)
                                            .withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.home_rounded,
                                        color:
                                            Color.fromARGB(255, 81, 147, 233),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Ingresa las credenciales del nuevo operario.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _labelGray,
                                  letterSpacing: -0.2,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── FORMULARIO
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BANNERS DE FEEDBACK arriba del formulario
                          if (_errorMessage != null) ...[
                            _buildFeedbackBanner(
                              message: _errorMessage!,
                              isError: true,
                              icon: Icons.error_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (_successMessage != null) ...[
                            _buildFeedbackBanner(
                              message: _successMessage!,
                              isError: false,
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // DATOS DE ACCESO
                          _buildSectionHeader("DATOS DE ACCESO"),
                          _buildSectionContainer(
                            child: Column(
                              children: [
                                _buildInputField(
                                  hint: "Nombre de usuario",
                                  controller: _usernameController,
                                  enabled: !_isLoading,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "El nombre de usuario es obligatorio.";
                                    }
                                    final cleaned = value.trim();
                                    if (cleaned.length < 4 ||
                                        cleaned.length > 20) {
                                      return "Debe contener entre 4 y 20 caracteres.";
                                    }
                                    if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                        .hasMatch(cleaned)) {
                                      return "Solo se permiten letras, números y guiones bajos";
                                    }
                                    return null;
                                  },
                                ),
                                const Divider(height: 1, indent: 16),
                                _buildInputField(
                                  hint: "Contraseña",
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  enabled: !_isLoading,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _labelGray,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "La contraseña es obligatoria.";
                                    }
                                    if (value.contains(' ')) {
                                      return "La contraseña no puede contener espacios.";
                                    }
                                    if (value.trim().length < 6) {
                                      return "La contraseña debe tener al menos 6 caracteres.";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ROL OPERATIVO
                          _buildSectionHeader("ASIGNACIÓN DE ROL OPERATIVO"),
                          _buildSectionContainer(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 4),
                              child: DropdownButtonFormField<String>(
                                value: _selectedRole,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded,
                                    color: _labelGray, size: 28),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                ),
                                style: const TextStyle(
                                  color: _titleColor,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                  fontWeight: FontWeight.w300,
                                ),
                                dropdownColor: _cardColor,
                                items: _roles.map((role) {
                                  return DropdownMenuItem<String>(
                                    value: role["value"],
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
                                          setState(
                                              () => _selectedRole = newValue);
                                        }
                                      },
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),

                          // BOTÓN
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _appleBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _appleBlue.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _procesarRegistro,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'Registrar Usuario',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 17,
                                        color: Colors.white,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── WIDGETS DE UI ───────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _labelGray,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          color: _titleColor,
          letterSpacing: -0.2,
          fontWeight: FontWeight.w300,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color.fromARGB(255, 81, 81, 81),
            fontSize: 16,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: const TextStyle(
            color: Colors.redAccent,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.8,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.only(top: 10, bottom: 10),
        ),
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
