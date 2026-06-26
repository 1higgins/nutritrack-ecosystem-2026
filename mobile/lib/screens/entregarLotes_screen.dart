import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/lote_service.dart';

class EntregaLotesScreen extends StatefulWidget {
  final String token;

  const EntregaLotesScreen({super.key, required this.token});

  @override
  State<EntregaLotesScreen> createState() => _EntregaLotesScreenState();
}

class _EntregaLotesScreenState extends State<EntregaLotesScreen> {
  // Colores estilo iOS
  static const Color _bgColor = Color(0xFFF2F2F7);
  static const Color _cardColor = Colors.white;
  static const Color _titleColor = Color(0xFF1C1C1E);
  static const Color _labelGray = Color(0xFF8E8E93);
  static const Color _appleBlue = Color(0xFF007AFF);

  final LoteService _loteService = LoteService();

  // Controladores — sin cambios de lógica
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreOpaController = TextEditingController();
  final TextEditingController _passwordLoteController = TextEditingController();

  bool _isLoadingAction = false;
  bool _obscurePassword = true;
  String? _localError;
  String? _successMessage;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreOpaController.dispose();
    _passwordLoteController.dispose();
    super.dispose();
  }

  // ── LÓGICA SIN CAMBIOS ──────────────────────────────────────────────────────
  String? _validarFormularioLote() {
    if (_codigoController.text.trim().isEmpty) {
      return "El nombre o código del lote es requerido.";
    }
    if (_nombreOpaController.text.trim().isEmpty) {
      return "El nombre del OPA (Emisor) es requerido.";
    }
    if (_passwordLoteController.text.trim().isEmpty) {
      return "La contraseña de seguridad es requerida.";
    }
    return null;
  }
  // ── FIN LÓGICA ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Confirmar Entrega',
                                  style: TextStyle(
                                    fontSize: 31,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.4,
                                    color: _titleColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
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
                                      color: Color.fromARGB(255, 81, 147, 233),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Ingresa los datos del lote para finalizar la entrega.',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DATOS DEL LOTE
                      _buildSectionHeader("DATOS DEL LOTE"),
                      _buildSectionContainer(
                        child: Column(
                          children: [
                            _buildInputField(
                              hint: "Nombre del lote",
                              controller: _codigoController,
                              enabled: !_isLoadingAction,
                            ),
                            const Divider(height: 1, indent: 16),
                            _buildInputField(
                              hint: "Nombre del OPA (Emisor)",
                              controller: _nombreOpaController,
                              enabled: !_isLoadingAction,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CONTRASEÑA
                      _buildSectionHeader("PASSWORD DE LOTE"),
                      _buildSectionContainer(
                        child: _buildInputField(
                          hint: "Contraseña del lote",
                          controller: _passwordLoteController,
                          obscureText: _obscurePassword,
                          enabled: !_isLoadingAction,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _labelGray,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      // BANNERS DE FEEDBACK
                      if (_localError != null) ...[
                        const SizedBox(height: 18),
                        _buildFeedbackBanner(
                          message: _localError!,
                          isError: true,
                          icon: Icons.error_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ],
                      if (_successMessage != null) ...[
                        const SizedBox(height: 18),
                        _buildFeedbackBanner(
                          message: _successMessage!,
                          isError: false,
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ],

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
                          onPressed: _isLoadingAction
                              ? null
                              : () async {
                                  final errorMsg = _validarFormularioLote();
                                  if (errorMsg != null) {
                                    setState(() => _localError = errorMsg);
                                    return;
                                  }
                                  setState(() {
                                    _isLoadingAction = true;
                                    _localError = null;
                                  });
                                  try {
                                    await _loteService
                                        .entregarLote(widget.token, {
                                      "nombre_opa":
                                          _nombreOpaController.text.trim(),
                                      "codigo_lote":
                                          _codigoController.text.trim(),
                                      "password_lote":
                                          _passwordLoteController.text.trim(),
                                    });
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingAction = false;
                                        _localError = null;
                                        _successMessage =
                                            "Entrega de lote finalizada con éxito.";
                                        _codigoController.clear();
                                        _nombreOpaController.clear();
                                        _passwordLoteController.clear();
                                      });
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        _isLoadingAction = false;
                                        _successMessage = null;
                                        final errorString =
                                            e.toString().toLowerCase();
                                        if (errorString
                                                .contains("ninguna medición") ||
                                            errorString.contains(
                                                "historial térmico") ||
                                            errorString.contains("esperando")) {
                                          _localError =
                                              "No se puede entregar: El lote no registra mediciones de temperatura.";
                                        } else if (errorString.contains(
                                                "no tiene ningún operario") ||
                                            errorString.contains("custodia") ||
                                            errorString.contains(
                                                "transporte vinculado")) {
                                          _localError =
                                              "No se puede entregar: Requiere un operario de transporte (OPT) vinculado.";
                                        } else if (errorString
                                                .contains("expirada") ||
                                            errorString.contains("not found") ||
                                            errorString.contains("invalid") ||
                                            errorString
                                                .contains("incorrecta") ||
                                            errorString
                                                .contains("no encontrado") ||
                                            errorString.contains("404") ||
                                            errorString.contains("inválidas")) {
                                          _localError =
                                              "Credenciales incorrectas o el lote no existe.";
                                        } else {
                                          _localError = e
                                              .toString()
                                              .replaceAll("Exception:", "")
                                              .replaceAll(
                                                  "LoteServiceException:", "")
                                              .trim();
                                        }
                                      });
                                    }
                                  }
                                },
                          child: _isLoadingAction
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Finalizar Entrega',
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
            ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
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
