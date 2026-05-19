import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

import '../main_wrapper.dart';

import 'package:animations/animations.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  bool _obscurePassword = true;

// Nuevo: Control de selección de rol

  String? _selectedRole;

  final TextEditingController _userController = TextEditingController();

  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super
        .initState(); // 📍 CORREGIDO: Termina en punto y coma, sin llaves continuas
    _checkAutoLogin(); // Se ejecuta inmediatamente después de inicializar el estado
  }

  void _checkAutoLogin() async {
    // Leemos el token usando el método que creamos en tu AuthService
    String? token = await _authService.getToken();

    if (token != null) {
      // Recuperamos el rol y usuario guardados para el handshake
      final prefs = await SharedPreferences.getInstance();
      String? savedRole = prefs.getString("user_role");

      if (mounted && savedRole != null) {
        debugPrint(
            "⚡ Redirección Automática: Token de sesión detectado en el dispositivo.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainWrapper(
              token: token,
              role: savedRole,
              userName:
                  "Operario Activo", // Identificador genérico de sesión persistente
            ),
          ),
        );
      }
    }
  }

  void _handleLogin() async {
    String? validationMessage;

    if (_userController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      validationMessage = "Debes completar las credenciales de acceso";
    }

    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResult? result = await _authService.login(
        _userController.text.trim(),
        _passController.text.trim(),
      );

      if (result != null) {
// --- TRADUCCIÓN DE ROLES (UI -> BACKEND) ---

        String serverRole = result.role; // Viene: "admin", "OPT" o "OPA"

        String selectedUI =
            _selectedRole!; // Viene: "Admin", "Transportista" o "Operario"

        bool isAuthorized = false;

// Lógica de validación cruzada

// Lógica de validación cruzada (Versión blindada)

        if (selectedUI == "Administrador" &&
            serverRole.toLowerCase() == "admin") {
          isAuthorized = true;
        } else if (selectedUI == "Transportista" &&
            serverRole.toUpperCase() == "OPT") {
          isAuthorized = true;
        } else if (selectedUI == "Operario" &&
            serverRole.toUpperCase() == "OPA") {
          isAuthorized = true;
        }

        if (!isAuthorized) {
          setState(() => _isLoading = false);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Acceso denegado: Este usuario no es $selectedUI"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );

          return;
        }

// Si pasa la validación, procedemos

        setState(() => _isLoading = false);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainWrapper(
              token: result.token,
              role: result.role,
              userName: _userController.text.trim(),
            ),
          ),
        );
      }
    } on NutriTrackException catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error de enlace con el servidor"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // ESPACIO SUPERIOR RESPONSIVE
                      SizedBox(
                        height: constraints.maxHeight * 0.08,
                      ),

                      // LOGO
                      Image.asset(
                        'assets/images/LOGO_NUTRITRACK.JPG',
                        height: constraints.maxHeight * 0.157,
                        fit: BoxFit.contain,
                      ),

                      // ESPACIO ENTRE LOGO Y CONTENIDO
                      SizedBox(
                        height: constraints.maxHeight * 0.01,
                      ),

                      // CONTENIDO CENTRAL
                      // CONTENIDO CENTRAL ESTABLE
                      SizedBox(
                        height: constraints.maxHeight * 0.55,
                        child: PageTransitionSwitcher(
                          duration: const Duration(milliseconds: 800),
                          reverse: _selectedRole == null,
                          transitionBuilder:
                              (child, animation, secondaryAnimation) {
                            return SharedAxisTransition(
                              animation: animation,
                              secondaryAnimation: secondaryAnimation,
                              transitionType:
                                  SharedAxisTransitionType.horizontal,
                              fillColor: Colors.transparent,
                              child: child,
                            );
                          },
                          child: _selectedRole == null
                              ? _buildRoleSelectorView()
                              : _buildLoginView(),
                        ),
                      ),

                      // ESPACIO FLEXIBLE
                      SizedBox(
                        height: constraints.maxHeight * 0.060,
                      ),

                      // FOOTER
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: constraints.maxHeight * 0.02,
                        ),
                        child: Text(
                          "v1.5.0 • NutriTrack Ecosystem 2026",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleSelectorView() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(
          "NutriTrack",
          "Cadena de Frío Inteligente",
        ),
        const SizedBox(height: 25),
        _buildRoleSelector(),
      ],
    );
  }

  Widget _buildLoginView() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 17),
        _buildHeader(
          "Bienvenido",
          "Accediendo como (${_selectedRole![0].toUpperCase()}${_selectedRole!.substring(1).toLowerCase()})",
        ),
        const SizedBox(height: 30),
        _buildLoginForm(),
        const SizedBox(height: 23),
        TextButton(
          onPressed: () => setState(() => _selectedRole = null),
          child: Text(
            "← Volver al selector de perfiles",
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

// --- FUNCIÓN AUXILIAR: Crea el título y subtítulo animado ---

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 8), // Distancia optimizada entre títulos

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

// --- WIDGET: SELECTOR DE ROLES ---

  Widget _buildRoleSelector() {
    return Column(
      key: const ValueKey(1),
      children: [
        _buildRoleCard(
          title: "Operario",
          subtitle: "Gestión de lotes y despacho",
          icon: Icons.inventory_2_rounded,
          color: const Color.fromARGB(255, 42, 148, 214),
          onTap: () => setState(() => _selectedRole = "Operario"),
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          title: "Transportista",
          subtitle: "Monitoreo y entrega de unidad",
          icon: Icons.local_shipping_rounded,
          color: const Color.fromARGB(255, 18, 209, 146),
          onTap: () => setState(() => _selectedRole = "Transportista"),
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          title: "Administrador",
          subtitle: "Control total del ecosistema",
          icon: Icons.admin_panel_settings_rounded,
          color: const Color.fromARGB(255, 114, 114, 104),
          onTap: () => setState(() => _selectedRole = "Administrador"),
        ),
      ],
    );
  }

// --- WIDGET: FORMULARIO DE LOGIN ---

  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInputField(
            controller: _userController,
            label: "Usuario",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _passController,
            label: "Contraseña",
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "INICIAR SESIÓN",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

// --- COMPONENTES AUXILIARES ---

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.height < 700
              ? 14
              : MediaQuery.of(context).size.width * 0.045,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
// Creamos un FocusNode local para detectar el clic

    return Focus(
      onFocusChange: (hasFocus) {
// Forzamos el redibujado para que el hint sepa si debe mostrarse o no

        setState(() {});
      },
      child: Builder(
        builder: (context) {
// Detectamos si el campo tiene el foco actualmente

          final bool isFocused = Focus.of(context).hasFocus;

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,

// LÓGICA DE FUSIÓN: Si está enfocado, el texto es transparente (desaparece)

// Si no, muestra el texto gris original.

                hintText: isFocused ? "" : label,

                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF94A3B8),
                  fontSize: 15,
                ),

// Mantenemos tus iconos y tamaños originales intactos

                prefixIcon:
                    Icon(icon, color: const Color(0xFF2374A6), size: 22),

                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      )
                    : null,

// Mantenemos tu padding exacto de 16 para no afectar el tamaño

                contentPadding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}
