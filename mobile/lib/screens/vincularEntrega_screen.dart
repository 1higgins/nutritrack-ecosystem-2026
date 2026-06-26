import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/lote_service.dart'; // Importación limpia de tu servicio

class VinculacionScreen extends StatefulWidget {
  final String token;

  const VinculacionScreen({super.key, required this.token});

  @override
  State<VinculacionScreen> createState() => _VinculacionScreenState();
}

class _VinculacionScreenState extends State<VinculacionScreen> {
  final LoteService _loteService = LoteService();

  // Controladores mapeados 1:1 con el esquema LoteVincular de FastAPI
  final TextEditingController _nombreOpaController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _passwordLoteController = TextEditingController();

  // Nodos de enfoque independientes
  final FocusNode _codigoFocus = FocusNode();
  final FocusNode _nombreOpaFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _codigoFocus.addListener(() => setState(() {}));
    _nombreOpaFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  bool _obscurePassword = true;
  bool _isLoadingAction = false;
  String? _localError;
  String? _successMessage;

  @override
  void dispose() {
    _nombreOpaController.dispose();
    _codigoController.dispose();
    _passwordLoteController.dispose();
    _codigoFocus.dispose();
    _nombreOpaFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validarFormularioVinculo() {
    if (_codigoController.text.trim().isEmpty) {
      return "El código del lote es requerido.";
    }
    if (_nombreOpaController.text.trim().isEmpty) {
      return "El nombre del OPA (Emisor) es requerido.";
    }
    if (_passwordLoteController.text.trim().isEmpty) {
      return "La contraseña de seguridad es requerida.";
    }
    return null;
  }

  Future<void> _ejecutarVinculacion() async {
    final errorValidacion = _validarFormularioVinculo();
    if (errorValidacion != null) {
      setState(() {
        _localError = errorValidacion;
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoadingAction = true;
      _localError = null;
      _successMessage = null;
    });

    try {
      final Map<String, dynamic> payloadVinculo = {
        "nombre_opa": _nombreOpaController.text.trim(),
        "codigo_lote": _codigoController.text.trim(),
        "password_lote": _passwordLoteController.text.trim(),
      };

      await _loteService.vincularLote(widget.token, payloadVinculo);

      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = null;
          _successMessage = "Conexión logística establecida con éxito.";

          _codigoController.clear();
          _nombreOpaController.clear();
          _passwordLoteController.clear();
        });
      }
    } on LoteServiceException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;

          // 🌟 AQUÍ ESTÁ EL CAMBIO QUE EVALÚA EL ERROR DEL BACKEND 🌟
          if (e.message.toLowerCase().contains("expirada") ||
              e.message.toLowerCase().contains("not found") ||
              e.message.toLowerCase().contains("invalid")) {
            _localError = "Credenciales incorrectas o el lote no existe.";
          } else {
            _localError = e.message;
          }

          _successMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = "Error inesperado al intentar enlazar la custodia.";
          _successMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: _isLoadingAction ? null : () => Navigator.pop(context),
        ),
        title: Text(
          "VINCULAR CUSTODIA",
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        shape:
            Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Monitorear nueva unidad",
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Text(
                "Ingrese el apretón de manos (handshake) logístico para tomar el control térmico.",
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 22),

              // 1. CÓDIGO DE LOTE
              _buildFormInputField(
                controller: _codigoController,
                focusNode: _codigoFocus,
                label: "CÓDIGO DE LOTE",
                icon: Icons.qr_code_scanner_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),

              // 2. NOMBRE DEL OPA
              _buildFormInputField(
                controller: _nombreOpaController,
                focusNode: _nombreOpaFocus,
                label: "NOMBRE DEL OPA (EMISOR)",
                icon: Icons.person_pin_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),

              // 3. CONTRASEÑA DE SEGURIDAD
              _buildFormInputField(
                controller: _passwordLoteController,
                focusNode: _passwordFocus,
                label: "CONTRASEÑA DE SEGURIDAD",
                icon: Icons.lock_outline_rounded,
                isPassword: _obscurePassword,
                enabled: !_isLoadingAction,
              ),

              // 📍 NUEVA UBICACIÓN: BANNERS DE FEEDBACK UBICADOS ABAJO 📍

              // --- BANNER DE ERROR ---
              if (_localError != null) ...[
                const SizedBox(height: 18),
                _buildFeedbackBanner(
                  message: _localError!,
                  isError: true,
                  icon: Icons.error_outline_rounded,
                  color: Colors.redAccent,
                ),
              ],

              // --- BANNER DE ÉXITO VERDE ---
              if (_successMessage != null) ...[
                const SizedBox(height: 18),
                _buildFeedbackBanner(
                  message: _successMessage!,
                  isError: false,
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                ),
              ],

              const SizedBox(height: 19),

              // --- BOTÓN PRINCIPAL DE VÍNCULO MINIMALISTA (OUTLINED) ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color.fromARGB(255, 59, 130, 246), width: 2),
                    foregroundColor: const Color(0xFF0F172A),
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoadingAction ? null : _ejecutarVinculacion,
                  child: _isLoadingAction
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F172A),
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "ESTABLECER VÍNCULO",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 59, 130, 246),
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha((0.02 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword,
        enabled: enabled,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: focusNode.hasFocus ? "" : label,
          hintStyle: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
          prefixIcon: Icon(icon,
              size: 20, color: const Color.fromARGB(255, 59, 130, 246)),

          // --- NUEVA SECCIÓN DE SUFFIXICON ---
          // Solo si la etiqueta contiene "CONTRASEÑA", inyectamos el botón del ojito
          suffixIcon: label.contains("CONTRASEÑA")
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      isPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                )
              : null,
          // ------------------------------------

          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
