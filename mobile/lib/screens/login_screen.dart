import 'package:flutter/material.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/services/auth_service.dart';

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

          String formattedName = userName.isNotEmpty
              ? userName[0].toUpperCase() + userName.substring(1)
              : 'Usuario';

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
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al conectar con el servidor.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
      backgroundColor: bgColor,
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.42,
            width: double.infinity,
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
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
