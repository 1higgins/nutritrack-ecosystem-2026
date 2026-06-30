import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lote_service.dart';

class CreacionLotesScreen extends StatefulWidget {
  final String token;
  // 📌 NUEVO: Recibimos el rol y usuario para validación de permisos en el backend
  final String role;
  final String userName;

  const CreacionLotesScreen({
    super.key,
    required this.token,
    required this.role,
    required this.userName,
  });

  @override
  State<CreacionLotesScreen> createState() => _CreacionLotesScreenState();
}

class _CreacionLotesScreenState extends State<CreacionLotesScreen> {
  static const Color _bgColor = Color(0xFFF2F2F7);
  static const Color _cardColor = Colors.white;
  static const Color _titleColor = Color(0xFF1C1C1E);
  static const Color _labelGray = Color(0xFF8E8E93);
  static const Color _appleBlue = Color(0xFF007AFF);

  final LoteService _loteService = LoteService();

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
    _codigoFocus.addListener(() => setState(() {}));
    _productoFocus.addListener(() => setState(() {}));
    _tempMinFocus.addListener(() => setState(() {}));
    _tempMaxFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  bool _isLoadingAction = false;
  bool _obscurePassword = true;
  String? _localError;
  String? _successMessage;

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

    if (min == null || max == null)
      return "Los rangos térmicos deben ser valores numéricos válidos.";
    if (min >= max)
      return "Coherencia térmica inválida: El valor mínimo debe ser estrictamente menor que el máximo.";
    return null;
  }

  Future<void> _ejecutarRegistroLote() async {
    final errorValidacion = _validarFormularioLote();
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
      final double min =
          double.parse(_tempMinController.text.replaceAll(',', '.'));
      final double max =
          double.parse(_tempMaxController.text.replaceAll(',', '.'));

      // 📌 NUEVO: El payload ahora envía el contexto completo para que el backend no deniegue el permiso
      final Map<String, dynamic> payloadLote = {
        "codigo_lote": _codigoController.text.trim(),
        "producto": _productoController.text.trim(),
        "temp_min_ideal": min,
        "temp_max_ideal": max,
        "password_lote": _passwordLoteController.text.trim(),
        "rol": widget.role, // Autorización
        "usuario": widget.userName, // Trazabilidad de quién lo creó
      };

      await _loteService.createLote(widget.token, payloadLote);

      if (mounted) {
        setState(() {
          _isLoadingAction = false;
          _localError = null;
          _successMessage = "Lote y parámetros térmicos registrados con éxito.";
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
          _localError =
              e.message; // Aquí es donde te lanzaba "Error de conexión..."
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
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
                                  'Registrar Lote',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.4,
                                    color: _titleColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
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
                              'Ingresa los datos del nuevo lote',
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("DATOS DEL PRODUCTO"),
                      _buildSectionContainer(
                        child: Column(
                          children: [
                            _buildInputField(
                                hint: "Codigo del lote",
                                controller: _codigoController,
                                focusNode: _codigoFocus,
                                enabled: !_isLoadingAction),
                            const Divider(height: 1, indent: 16),
                            _buildInputField(
                                hint: "Nombre del producto",
                                controller: _productoController,
                                focusNode: _productoFocus,
                                enabled: !_isLoadingAction),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader("LIMITES DE TEMPERATURA"),
                      _buildSectionContainer(
                        child: Row(
                          children: [
                            Expanded(
                                child: _buildInputField(
                                    hint: "Min (°C)",
                                    controller: _tempMinController,
                                    focusNode: _tempMinFocus,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    enabled: !_isLoadingAction)),
                            Container(
                                width: 1,
                                height: 50,
                                color: _labelGray.withOpacity(0.2)),
                            Expanded(
                                child: _buildInputField(
                                    hint: "Max (°C)",
                                    controller: _tempMaxController,
                                    focusNode: _tempMaxFocus,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    enabled: !_isLoadingAction)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader("PASSWORD DE LOTE"),
                      _buildSectionContainer(
                        child: _buildInputField(
                          hint: "Contraseña del lote",
                          controller: _passwordLoteController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          enabled: !_isLoadingAction,
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _labelGray,
                                size: 20),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      if (_localError != null) ...[
                        const SizedBox(height: 18),
                        _buildFeedbackBanner(
                            message: _localError!,
                            isError: true,
                            icon: Icons.error_outline_rounded,
                            color: Colors.redAccent),
                      ],
                      if (_successMessage != null) ...[
                        const SizedBox(height: 18),
                        _buildFeedbackBanner(
                            message: _successMessage!,
                            isError: false,
                            icon: Icons.check_circle_outline_rounded,
                            color: const Color(0xFF10B981)),
                      ],
                      const SizedBox(height: 50),
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
                          onPressed:
                              _isLoadingAction ? null : _ejecutarRegistroLote,
                          child: _isLoadingAction
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('Registrar Lote',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                      color: Colors.white,
                                      letterSpacing: -0.4)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
      child: Text(title,
          style: const TextStyle(
              color: _labelGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1)),
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
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputField(
      {required String hint,
      required TextEditingController controller,
      required FocusNode focusNode,
      TextInputType keyboardType = TextInputType.text,
      bool obscureText = false,
      bool enabled = true,
      Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        style: const TextStyle(
            fontSize: 16,
            color: _titleColor,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w300),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color.fromARGB(255, 81, 81, 81), fontSize: 16),
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

  Widget _buildFeedbackBanner(
      {required String message,
      required bool isError,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: color.withAlpha((0.08 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withAlpha((0.3 * 255).round()), width: 1)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      color:
                          isError ? Colors.redAccent : const Color(0xFF065F46),
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
