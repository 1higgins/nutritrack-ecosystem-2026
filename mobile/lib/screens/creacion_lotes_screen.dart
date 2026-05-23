import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/lote_service.dart'; // Importación verificada del servicio

class CreacionLotesScreen extends StatefulWidget {
  final String token;

  const CreacionLotesScreen({super.key, required this.token});

  @override
  State<CreacionLotesScreen> createState() => _CreacionLotesScreenState();
}

class _CreacionLotesScreenState extends State<CreacionLotesScreen> {
  // Conexión profesional al Singleton del Servicio de Lotes
  final LoteService _loteService = LoteService();

  // Controladores de texto unificados bajo el modelo de negocio
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _productoController = TextEditingController();
  final TextEditingController _tempMinController = TextEditingController();
  final TextEditingController _tempMaxController = TextEditingController();
  final TextEditingController _passwordLoteController = TextEditingController();
  final FocusNode _codigoFocus = FocusNode();
  final FocusNode _productoFocus = FocusNode();
  final FocusNode _tempMinFocus = FocusNode();
  final FocusNode _tempMaxFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Escuchan cuando pones el dedo para refrescar el hintText de inmediato
    _codigoFocus.addListener(() => setState(() {}));
    _productoFocus.addListener(() => setState(() {}));
    _tempMinFocus.addListener(() => setState(() {}));
    _tempMaxFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  // Gestión de estados reactivos en UI
  // Gestión de estados reactivos en UI
  bool _isLoadingAction = false;
  bool _obscurePassword = true;
  String? _localError;
  String? _successMessage; // 🌟 Nuevo rastreador de estado exitoso

  @override
  void dispose() {
    _codigoController.dispose();
    _productoController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _passwordLoteController.dispose();
    _codigoFocus.dispose();
    _productoFocus.dispose();
    _tempMinFocus.dispose();
    _tempMaxFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // Validador preventivo de front-end antes de realizar mutaciones de red
  String? _validarFormularioLote() {
    if (_codigoController.text.trim().isEmpty)
      return "El código de lote es requerido.";
    if (_productoController.text.trim().isEmpty)
      return "El nombre del producto es requerido.";
    if (_tempMinController.text.trim().isEmpty)
      return "La temperatura mínima es requerida.";
    if (_tempMaxController.text.trim().isEmpty)
      return "La temperatura máxima es requerida.";
    if (_passwordLoteController.text.trim().isEmpty)
      return "La contraseña de seguridad es requerida.";

    final double? min =
        double.tryParse(_tempMinController.text.replaceAll(',', '.'));
    final double? max =
        double.tryParse(_tempMaxController.text.replaceAll(',', '.'));

    if (min == null || max == null) {
      return "Los rangos térmicos deben ser valores numéricos válidos.";
    }
    if (min >= max) {
      return "Coherencia térmica inválida: El valor mínimo debe ser estrictamente menor que el máximo.";
    }
    return null;
  }

  // Hilo de ejecución asíncrono hacia FastAPI
  // Hilo de ejecución asíncrono hacia FastAPI
  Future<void> _ejecutarRegistroLote() async {
    final errorValidacion = _validarFormularioLote();
    if (errorValidacion != null) {
      setState(() {
        _localError = errorValidacion;
        _successMessage =
            null; // Limpia éxitos viejos si el nuevo intento falla
      });
      return;
    }

    setState(() {
      _isLoadingAction = true;
      _localError = null;
      _successMessage =
          null; // Limpia la pantalla al iniciar una nueva petición
    });

    try {
      final double min =
          double.parse(_tempMinController.text.replaceAll(',', '.'));
      final double max =
          double.parse(_tempMaxController.text.replaceAll(',', '.'));

      // Payload mapeado de forma idéntica a schemas.LoteCreate de Pydantic
      final Map<String, dynamic> payloadLote = {
        "codigo_lote": _codigoController.text.trim(),
        "producto": _productoController.text.trim(),
        "temp_min_ideal": min,
        "temp_max_ideal": max,
        "password_lote": _passwordLoteController.text.trim(),
      };

      // Despacho vía canal HTTP seguro
      await _loteService.createLote(widget.token, payloadLote);

      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = null;
          // Inyectamos el mensaje sin alterar el control de la pantalla
          _successMessage = "Lote y parámetros térmicos registrados con éxito.";

          // Limpieza profesional para dejar el formulario listo para el SIGUIENTE lote
          _codigoController.clear();
          _productoController.clear();
          _tempMinController.clear();
          _tempMaxController.clear();
          _passwordLoteController.clear();
        });
      }
    } on LoteServiceException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = e.message; // Captura exacta del detail de FastAPI
          _successMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = "Error inesperado de procesamiento en la app.";
          _successMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 249, 249),
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
          "NUEVO DESPACHO",
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
                "Registrar Lotes",
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Text(
                "Establezca los parámetros de control críticos para la telemetría.",
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 22),
              // 1. CÓDIGO DE LOTE
              _buildFormInputField(
                controller: _codigoController,
                focusNode:
                    _codigoFocus, // 👈 Su propio nodo asignado correctamente
                label: "CÓDIGO DE LOTE",
                icon: Icons.qr_code_scanner_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),

              // 2. PRODUCTO / CARGA
              _buildFormInputField(
                controller: _productoController,
                focusNode:
                    _productoFocus, // 👈 Su propio nodo asignado correctamente
                label: "PRODUCTO / CARGA",
                icon: Icons.inventory_2_outlined,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),

              // 3. RANGOS TÉRMICOS
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFormInputField(
                      controller: _tempMinController,
                      focusNode:
                          _tempMinFocus, // 👈 Su propio nodo asignado correctamente
                      label: "MIN °C",
                      icon: Icons.ac_unit_rounded,
                      isNumber: true,
                      enabled: !_isLoadingAction,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormInputField(
                      controller: _tempMaxController,
                      focusNode:
                          _tempMaxFocus, // 👈 Su propio nodo asignado correctamente
                      label: "MAX °C",
                      icon: Icons.wb_sunny_rounded,
                      isNumber: true,
                      enabled: !_isLoadingAction,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4. CONTRASEÑA DE SEGURIDAD
              _buildFormInputField(
                controller: _passwordLoteController,
                focusNode: _passwordFocus,
                label: "CONTRASEÑA DE SEGURIDAD",
                icon: Icons.lock_outline_rounded,
                isPasswordField: true,
                enabled: !_isLoadingAction,
              ),
              // 📍 SECCIÓN DE FEEDBACK INTEGRADA CON COMPORTAMIENTO VINCULACIÓN 📍

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
              // 4. BOTÓN DE REGISTRO MINIMALISTA (OUTLINED)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    // Define el color del borde y el texto en estados normales
                    side: const BorderSide(
                        color: Color.fromARGB(255, 59, 130, 246), width: 2),
                    foregroundColor: const Color(0xFF0F172A),
                    backgroundColor: const Color.fromARGB(
                        255, 255, 255, 255), // Totalmente sin fondo
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isLoadingAction ? null : _ejecutarRegistroLote,
                  child: _isLoadingAction
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Color(0xFF0F172A),
                              strokeWidth: 2.5), // Indicador ahora es negro
                        )
                      : Text(
                          "CONFIRMAR REGISTRO",
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

  Widget _buildFormInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode, // 📍 1. NUEVO PARAMETRO REQUERIDO
    bool isNumber = false,
    bool isPasswordField = false,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0)
                  .withAlpha((0.02 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode, // 📍 2. ASIGNAMOS EL NODE AL TEXTFIELD
        obscureText: isPasswordField == true && _obscurePassword,
        enabled: enabled,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: focusNode.hasFocus ? "" : label,
          hintStyle: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: const Color.fromARGB(255, 59, 130, 246),
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
