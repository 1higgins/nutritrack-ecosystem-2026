import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/lote_service.dart';

class EntregaLotesScreen extends StatefulWidget {
  final String token;

  const EntregaLotesScreen({super.key, required this.token});

  @override
  State<EntregaLotesScreen> createState() => _EntregaLotesScreenState();
}

class _EntregaLotesScreenState extends State<EntregaLotesScreen> {
  final LoteService _loteService = LoteService();

  // Controladores idénticos a tu motor de formularios original
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _nombreOpaController = TextEditingController();
  final TextEditingController _passwordLoteController = TextEditingController();

  bool _isLoadingAction = false;
  String? _localError;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreOpaController.dispose();
    _passwordLoteController.dispose();
    super.dispose();
  }

  // Validación exacta basada en tu lógica nativa
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
          onPressed: _isLoadingAction ? null : () => Navigator.pop(context),
        ),
        title: Text(
          "CONFIRMAR ENTREGA",
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Finalizar entregas",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Complete los datos de la contraparte para asentar el cierre definitivo del flujo logístico en el backend.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),

              // Campo 1: Nombre o Código del Lote (Mapeado a _codigoController)
              _buildModernField(
                controller: _codigoController,
                label: "NOMBRE DEL LOTE",
                icon: Icons.label_important_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 16),

              // Campo 2: Nombre del OPA (Mapeado a _nombreOpaController)
              _buildModernField(
                controller: _nombreOpaController,
                label: "NOMBRE DEL OPA (EMISOR)",
                icon: Icons.person_pin_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 16),

              // Campo 3: Contraseña de Seguridad (Mapeado a _passwordLoteController)
              _buildModernField(
                controller: _passwordLoteController,
                label: "CONTRASEÑA DE SEGURIDAD",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                enabled: !_isLoadingAction,
              ),

              // Alertas de Error dinámicas en sincronía con tu diseño original
              if (_localError != null) ...[
                const SizedBox(height: 16),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 19),

              // Botón de Confirmación con el color Ámbar Logístico exacto de tu condicional (0xFFF59E0B)
              // BOTÓN DE FINALIZAR ENTREGA MINIMALISTA (OUTLINED)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color.fromARGB(255, 59, 130, 246),
                        width: 2), // Borde negro
                    foregroundColor: const Color(
                        0xFF0F172A), // Color para el efecto ripple / texto
                    backgroundColor:
                        const Color.fromARGB(255, 255, 255, 255), // Sin fondo
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                            await _loteService.entregarLote(widget.token, {
                              "nombre_opa": _nombreOpaController.text.trim(),
                              "codigo_lote": _codigoController.text.trim(),
                              "password_lote":
                                  _passwordLoteController.text.trim(),
                            });

                            if (mounted) {
                              setState(() => _isLoadingAction = false);
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isLoadingAction = false;
                                _localError =
                                    e.toString().replaceAll("Exception:", "");
                              });
                            }
                          }
                        },
                  child: _isLoadingAction
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color:
                                Color(0xFF0F172A), // Indicador de carga negro
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "FINALIZAR ENTREGA",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(
                                255, 59, 130, 246), // Letras negras
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

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.02 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            enabled: enabled,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              labelStyle:
                  const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
