import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mobile/services/lote_service.dart';

class LotesPage extends StatefulWidget {
  final String token;
  const LotesPage({super.key, required this.token});

  @override
  State<LotesPage> createState() => _LotesPageState();
}

class _LotesPageState extends State<LotesPage> {
  static const Color bgColor = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color titleColor = Color(0xFF1C1C1E);
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color appleBlue = Color(0xFF007AFF);
  // Controladores e Inputs de Datos
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _productoController = TextEditingController();
  final _tempMinController = TextEditingController();
  final _tempMaxController = TextEditingController();
  final _passwordLoteController = TextEditingController();
  final _cantidadController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _productoController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _passwordLoteController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  // 1. Instanciamos el servicio (asegúrate de importar tu archivo lote_service.dart arriba)
  final LoteService _loteService = LoteService();

  void _enviarLoteAlBackend() async {
    // Validar el formulario de Flutter
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, rellene todos los campos requeridos.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Ejecutar la petición HTTP real mapeando los controladores
      final bool exito = await _loteService.registrarLote(
        token: widget.token, // Usamos el token que pasamos por constructor
        codigoLote: _codigoController.text.trim(),
        producto: _productoController.text.trim(),
        tempMinIdeal: double.parse(_tempMinController.text.trim()),
        tempMaxIdeal: double.parse(_tempMaxController.text.trim()),
        cantidad: int.parse(
          _cantidadController.text.trim(),
        ), // Backend pide entero
        passwordLote: _passwordLoteController.text.trim(),
      );

      if (!mounted) return;

      if (exito) {
        // Alerta de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lote ${_codigoController.text} registrado con éxito.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Volvemos al Home automáticamente
        Navigator.pop(context);
      } else {
        // Alerta si el servicio retornó false (error de rol o duplicado)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error del servidor: Verifica tus permisos o si el lote ya existe.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // En caso de que el double.parse o int.parse fallen por caracteres inválidos
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, introduce formatos numéricos válidos en temperaturas y cantidad.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrar Lote',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.4,
                                color: titleColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ingresa los datos del nuevo lote',
                              style: TextStyle(
                                fontSize: 14,
                                color: labelGray,
                                letterSpacing: -0.2,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appleBlue.withOpacity(0.10),
                          ),
                          child: const Icon(
                            Icons.store_rounded,
                            size: 18,
                            color: appleBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Formulario
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── DATOS DEL PRODUCTO
                        _buildSectionHeader("DATOS DEL PRODUCTO"),
                        _buildFormContainer(
                          child: Column(
                            children: [
                              _buildInputField(
                                hint: "Codigo del producto",
                                controller: _codigoController,
                              ),
                              const Divider(height: 1, indent: 16),
                              _buildInputField(
                                hint: "Nombre del producto",
                                controller: _productoController,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildSectionHeader("CANTIDAD DEL PRODUCTO"),
                        _buildFormContainer(
                          child: _buildInputField(
                            hint: "Cantidad en unidades",
                            controller: _cantidadController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── LÍMITES CRÍTICOS (EN PARALELO) ─────────────────────
                        _buildSectionHeader("LIMITES DE TEMPERATURA"),
                        _buildFormContainer(
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  hint: "Temp. minima",
                                  controller: _tempMinController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: labelGray.withOpacity(0.2),
                              ),
                              Expanded(
                                child: _buildInputField(
                                  hint: "Temp. máxima",
                                  controller: _tempMaxController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildSectionHeader('PASSWORD DE LOTE'),
                        _buildFormContainer(
                          child: _buildInputField(
                            hint: "Contraseña del lote",
                            controller: _passwordLoteController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            obscureText: true,
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Botón de registro de lote
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: CupertinoButton(
                            color: appleBlue,
                            borderRadius: BorderRadius.circular(20),
                            padding: EdgeInsets.zero,
                            onPressed: _isLoading ? null : _enviarLoteAlBackend,
                            child: _isLoading
                                ? const CupertinoActivityIndicator(
                                    color: Colors.white,
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 6),
                                      Text(
                                        'Registrar Lote',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17,
                                          color: Colors.white,
                                          letterSpacing: -0.4,
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
      child: Text(
        title,
        style: const TextStyle(
          color: labelGray,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildFormContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 16,
              color: titleColor,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w300,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 81, 81, 81),
                fontSize: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,

              // Estilo del texto del validator ("Requerido")
              errorStyle: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
              ),

              isDense: true,
              contentPadding: const EdgeInsets.only(top: 6, bottom: 2),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          ),
        ],
      ),
    );
  }
}
