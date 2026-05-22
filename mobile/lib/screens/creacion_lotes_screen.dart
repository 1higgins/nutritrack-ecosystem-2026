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

  // Gestión de estados reactivos en UI
  bool _isLoadingAction = false;
  String? _localError;

  @override
  void dispose() {
    _codigoController.dispose();
    _productoController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _passwordLoteController.dispose();
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
  Future<void> _ejecutarRegistroLote() async {
    final errorValidacion = _validarFormularioLote();
    if (errorValidacion != null) {
      setState(() => _localError = errorValidacion);
      return;
    }

    setState(() {
      _isLoadingAction = true;
      _localError = null;
    });

    try {
      final double min =
          double.parse(_tempMinController.text.replaceAll(',', '.'));
      final double max =
          double.parse(_tempMaxController.text.replaceAll(',', '.'));

      // Payload mapeado de forma idéntica a schemas.LoteCreate de Pydantic (Snake_case)
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
        setState(() => _isLoadingAction = false);
        // Retornamos true para notificar a monitor_screen.dart que debe re-ejecutar fetchLotes
        Navigator.pop(context, true);
      }
    } on LoteServiceException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = e
              .message; // Captura exacta del detail de la HTTP Exception de FastAPI
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = "Error inesperado de procesamiento en la app.";
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
              _buildFormInputField(
                controller: _codigoController,
                label: "CÓDIGO DE LOTE",
                icon: Icons.qr_code_scanner_rounded,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),
              _buildFormInputField(
                controller: _productoController,
                label: "PRODUCTO / CARGA",
                icon: Icons.inventory_2_outlined,
                enabled: !_isLoadingAction,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFormInputField(
                      controller: _tempMinController,
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
                      label: "MAX °C",
                      icon: Icons.wb_sunny_rounded,
                      isNumber: true,
                      enabled: !_isLoadingAction,
                    ),
                  ),
                ],
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
                    backgroundColor: const Color(0xFF0F172A),
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
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "CONFIRMAR REGISTRO",
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
    bool isNumber = false,
    bool isPassword = false,
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
        obscureText: isPassword,
        enabled: enabled,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
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
              size: 20, color: const Color.fromARGB(255, 81, 148, 255)),
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
