import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/screens/home_screen.dart';
import '../services/auth_service.dart';
import 'package:animations/animations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedRole;

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    String? token = await _authService.getToken();
    String? savedRole = await _authService.getRole();
    String? savedUsername = await _authService.getUsername();

    if (token != null && savedRole != null && savedUsername != null) {
      if (!mounted) return;

      debugPrint(
          "⚡ Redirección Automática Blindada: Sesión recuperada para: $savedUsername ($savedRole)");

      //nos vamos al homescreen con el token el rol y el nomrbre usuario
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            token: token,
            role: savedRole,
            userName: savedUsername,
          ),
        ),
      );
    }
  }

  //validaciones
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
        if (result.role != _selectedRole) {
          setState(() => _isLoading = false);
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Acceso denegado: Este usuario no es $_selectedRole"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        setState(() => _isLoading = false);
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de enlace con el servidor"),
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // ESPACIO SUPERIOR RESPONSIVE
                        SizedBox(height: constraints.maxHeight * 0.05),

                        // LOGO
                        Image.asset(
                          'assets/images/LOGO_NUTRITRACK.JPG',
                          height: constraints.maxHeight * 0.14,
                          fit: BoxFit.contain,
                        ),

                        // ESPACIO ENTRE LOGO Y CONTENIDO
                        const SizedBox(height: 25),

                        // CONTENIDO CENTRAL DINÁMICO
                        PageTransitionSwitcher(
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

                        // AHORA SÍ: El Spacer funciona perfectamente aquí gracias al IntrinsicHeight
                        const Spacer(),

                        // FOOTER SIEMPRE ABAJO
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 5),
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
        _buildHeader("NutriTrack", "Cadena de Frío Inteligente"),
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
        const SizedBox(height: 10),
        _buildHeader(
          "Bienvenido",
          "Accediendo como (${_selectedRole![0].toUpperCase()}${_selectedRole!.substring(1).toLowerCase()})",
        ),
        const SizedBox(height: 25),
        _buildLoginForm(),
        const SizedBox(height: 20),
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
        const SizedBox(height: 8),
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

  Widget _buildLoginForm() {
    return Container(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
                color: color.withValues(alpha: 0.1),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        textAlignVertical: TextAlignVertical.center,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: label,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF94A3B8),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF2374A6),
            size: 22,
          ),
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
                    () => _obscurePassword = !_obscurePassword,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
