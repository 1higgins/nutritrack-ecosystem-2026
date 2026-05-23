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
                isPasswordField: true,
                enabled: !_isLoadingAction,
              ),

              // Alertas de Error dinámicas arriba del botón (Mantiene foco en los inputs)
              if (_localError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14), // 👈 Cambiado de 12 a 14
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha((0.08 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.redAccent.withAlpha((0.3 * 255).round()),
                        width: 1), // 👈 ESTA LÍNEA FALTA
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12), // 👈 Cambiado de 10 a 12
                      Expanded(
                        child: Text(
                          _localError!,
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600, // 👈 Cambiado de bold a w600
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 🟢 CORREGIDO: Banner de Éxito dinámico reubicado ARRIBA del botón
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                _buildSuccessBanner(_successMessage!),
              ],

              const SizedBox(height: 19),

              // BOTÓN DE FINALIZAR ENTREGA MINIMALISTA (OUTLINED)
              SizedBox(
                width: double.infinity,
                height: 55,
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
                              setState(() {
                                _isLoadingAction = false;
                                _localError = null;
                                _successMessage =
                                    "Entrega de lote finalizada con éxito.";

                                // 👈 ESTO FALTA: Limpieza para dejar el formulario listo
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

                                final errorString = e.toString().toLowerCase();

                                if (errorString.contains("ninguna medición") ||
                                    errorString.contains("historial térmico") ||
                                    errorString.contains("esperando")) {
                                  _localError =
                                      "No se puede entregar: El lote no registra mediciones de temperatura.";
                                } else if (errorString
                                        .contains("no tiene ningún operario") ||
                                    errorString.contains("custodia") ||
                                    errorString
                                        .contains("transporte vinculado")) {
                                  _localError =
                                      "No se puede entregar: Requiere un operario de transporte (OPT) vinculado.";
                                } else if (errorString.contains("expirada") ||
                                    errorString.contains("not found") ||
                                    errorString.contains("invalid") ||
                                    errorString.contains("incorrecta") ||
                                    errorString.contains("no encontrado") ||
                                    errorString.contains("404") ||
                                    errorString.contains("inválidas")) {
                                  _localError =
                                      "Credenciales incorrectas o el lote no existe.";
                                } else {
                                  _localError = e
                                      .toString()
                                      .replaceAll("Exception:", "")
                                      .replaceAll("LoteServiceException:", "")
                                      .trim();
                                }
                              });
                            }
                          }
                        },
                  child: _isLoadingAction
                      ? const SizedBox(
                          height: 24, // 👈 Corregido a 24
                          width: 24, // 👈 Corregido a 24
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F172A),
                            strokeWidth: 2.5, // 👈 Corregido a 2.5
                          ),
                        )
                      : Text(
                          "FINALIZAR ENTREGA",
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

  // Abajo de esto permanece intacto tu widget _buildModernField hasta el final de la clase

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPasswordField = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16), // 👈 Cambiado de 12 a 16
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
            obscureText: isPasswordField ? _obscurePassword : false,
            enabled: enabled,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              labelStyle:
                  const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              prefixIcon: Icon(
                icon,
                size: 20,
                color: const Color(0xFF3B82F6),
              ),
              suffixIcon: isPasswordField
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    )
                  : null,
              filled: true,
              fillColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16), // 👈 Cambiado de 12 a 16
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 18), // 👈 Cambiado de 16 a 18
            ),
          ),
        ),
      ],
    );
  }

  // 🟢 AÑADE ESTO (Al final de la clase, abajo de _buildModernField)
  // 🟢 CORREGIDO: Banner de éxito con colores, íconos y textos idénticos a las otras vistas
  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14), // 👈 Corregido a 14
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withAlpha((0.2 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF10B981),
            size: 20, // 👈 Corregido a 20
          ),
          const SizedBox(width: 12), // 👈 Corregido a 12
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: const Color(
                    0xFF065F46), // 👈 Corregido al verde exacto de creación
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
