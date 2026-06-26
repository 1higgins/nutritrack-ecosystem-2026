import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/services/auth_service.dart';
=======
import 'package:mobile_app/screens/home_screen.dart';
import '../services/auth_service.dart';
import 'package:animations/animations.dart';
>>>>>>> Stashed changes

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  static const Color appleBlue = Color(0xFF007AFF);
  static const Color bgColor = Color(0xFFF2F2F7); // iOS system gray
  static const Color cardColor = Colors.white;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final success = await _authService.login(
          _usernameController.text,
          _passwordController.text,
        );
        if (success != null) {
          String userName = _usernameController.text.trim();

<<<<<<< Updated upstream
          String formattedName = userName.isNotEmpty
              ? userName[0].toUpperCase() + userName.substring(1)
              : 'Usuario';

=======
    if (token != null && savedRole != null && savedUsername != null) {
      if (!mounted) return;

      debugPrint(
          "⚡ Redirección Automática Blindada: Sesión recuperada para: $savedUsername ($savedRole)");

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
>>>>>>> Stashed changes
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(username: formattedName, token: success.token),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nombre de usuario o contraseña incorrectos.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
<<<<<<< Updated upstream
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con el servidor.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
=======

        setState(() => _isLoading = false);
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              token: result.token,
              role: result.role,
              userName: _userController.text.trim(),
>>>>>>> Stashed changes
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
<<<<<<< Updated upstream
      backgroundColor: bgColor,
      body: Column(
=======
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
                            style: TextStyle(
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
          child: const Text(
            "← Volver al selector de perfiles",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.25,
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
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            letterSpacing: -0.25,
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
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
>>>>>>> Stashed changes
        children: [
          SizedBox(
            height: screenHeight * 0.42,
            width: double.infinity,
<<<<<<< Updated upstream
            child: Stack(fit: StackFit.expand),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),

                    const Text(
                      'Bienvenido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        color: Color(0xFF1C1C1E),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.5,
=======
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "INICIAR SESIÓN",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.25,
>>>>>>> Stashed changes
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Inocuidad alimentaria en tiempo real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 40),

                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildField(
                            controller: _usernameController,
                            hint: 'Usuario',
                            icon: Icons.person_outline_rounded,
                            isFirst: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 52),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: const Color.fromARGB(255, 211, 211, 213),
                            ),
                          ),
                          _buildField(
                            controller: _passwordController,
                            hint: 'Contraseña',
                            icon: Icons.lock_outline_rounded,
                            obscure: true,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Login button
                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color.fromARGB(255, 37, 142, 255),
                              strokeWidth: 2,
                            ),
                          )
                        : SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appleBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _buildField({
=======
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
          borderRadius: BorderRadius.circular(30),
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
                borderRadius: BorderRadius.circular(30),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      letterSpacing: -0.25,
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
>>>>>>> Stashed changes
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
<<<<<<< Updated upstream
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 14 : 0),
      topRight: Radius.circular(isFirst ? 14 : 0),
      bottomLeft: Radius.circular(isLast ? 14 : 0),
      bottomRight: Radius.circular(isLast ? 14 : 0),
    );

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Color(0xFF1C1C1E),
        fontSize: 17,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color.fromARGB(255, 0, 0, 0), // blue hint label
          fontSize: 17,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.5,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: const Color(0xFF007AFF), size: 20),
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 255, 255, 255),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 255, 255, 255),
            width: 1,
=======
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF1E293B),
          letterSpacing: -0.25,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: label,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 15,
            letterSpacing: -0.25,
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
            vertical: 16,
            horizontal: 20,
>>>>>>> Stashed changes
          ),
        ),
        errorStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
    );
  }
}
