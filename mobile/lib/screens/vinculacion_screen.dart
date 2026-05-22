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

  bool _isLoadingAction = false;
  String? _localError;

  @override
  void dispose() {
    _nombreOpaController.dispose();
    _codigoController.dispose();
    _passwordLoteController.dispose();
    super.dispose();
  }

  String? _validarFormularioVinculo() {
    if (_nombreOpaController.text.trim().isEmpty)
      return "El nombre del OPA (Emisor) es requerido.";
    if (_codigoController.text.trim().isEmpty)
      return "El código del lote es requerido.";
    if (_passwordLoteController.text.trim().isEmpty)
      return "La contraseña de seguridad es requerida.";
    return null;
  }

  Future<void> _ejecutarVinculacion() async {
    final errorValidacion = _validarFormularioVinculo();
    if (errorValidacion != null) {
      setState(() => _localError = errorValidacion);
      return;
    }

    setState(() {
      _isLoadingAction = true;
      _localError = null;
    });

    try {
      // JSON estructurado idéntico al Pydantic "LoteVincular" del Backend
      final Map<String, dynamic> payloadVinculo = {
        "nombre_opa": _nombreOpaController.text.trim(),
        "codigo_lote": _codigoController.text.trim(),
        "password_lote": _passwordLoteController.text.trim(),
      };

      await _loteService.vincularLote(widget.token, payloadVinculo);

      if (mounted) {
        setState(() => _isLoadingAction = false);
        // Retornamos 'true' para avisar a la pantalla madre que actualice el listado de lotes
        Navigator.pop(context, true);
      }
    } on LoteServiceException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = e
              .message; // Muestra el mensaje exacto (401, 400 Conflicto, etc.) enviado por FastAPI
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = "Error inesperado al intentar enlazar la custodia.";
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
              _buildFormInputField(
                controller: _codigoController,
                label: "CÓDIGO DE LOTE",
                icon: Icons.qr_code_scanner_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),
              _buildFormInputField(
                controller: _nombreOpaController,
                label: "NOMBRE DEL OPA (EMISOR)",
                icon: Icons.person_pin_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),
              _buildFormInputField(
                controller: _passwordLoteController,
                label: "CONTRASEÑA DE SEGURIDAD",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                enabled: !_isLoadingAction,
              ),
              if (_localError != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha((0.08 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _localError!,
                          style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 19),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xFF10B981), // Color Verde Esmeralda enfocado en Transporte/Rutas
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isLoadingAction ? null : _ejecutarVinculacion,
                  child: _isLoadingAction
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "ESTABLECER VÍNCULO",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
        obscureText: isPassword,
        enabled: enabled,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon,
              size: 20,
              color: const Color(
                  0xFF10B981)), // Sincronizado con el color de la pantalla
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
}
