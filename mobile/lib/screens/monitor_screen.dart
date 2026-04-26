import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lote_model.dart';
import '../services/lote_service.dart';
import 'lote_detail_screen.dart';

class MonitorScreen extends StatefulWidget {
  final String token;
  final String role;

  const MonitorScreen({super.key, required this.token, required this.role});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen>
    with TickerProviderStateMixin {
  final LoteService _loteService = LoteService();
  late Future<List<Lote>> _futureLotes;

  // --- CONTROLADORES INDUSTRIALES ---
  final _codigoController = TextEditingController();
  final _productoController = TextEditingController();
  final _tempMinController = TextEditingController();
  final _tempMaxController = TextEditingController();
  final _passwordLoteController = TextEditingController();
  final _nombreOpaController = TextEditingController();

  // Estado de carga para botones
  bool _isLoadingAction = false;
  String _currentFormType = ""; // Almacena: 'crear', 'vincular' o 'entregar'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureLotes = _loteService.fetchLotes(widget.token);
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _productoController.dispose();
    _tempMinController.dispose();
    _tempMaxController.dispose();
    _passwordLoteController.dispose();
    _nombreOpaController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DE LÓGICA ---

  String? _validarFormularioLote() {
    // 1. VALIDACIÓN TRANSVERSAL (Obligatorio para todos: Crear, Vincular, Entregar)
    if (_codigoController.text.trim().isEmpty) {
      return "El Código/Nombre del lote es obligatorio";
    }

    if (_passwordLoteController.text.trim().length < 4) {
      return "La contraseña de seguridad debe tener al menos 4 caracteres";
    }

    // 2. VALIDACIÓN POR FLUJO ESPECÍFICO
    switch (_currentFormType) {
      case "crear":
        // Para crear, el producto ES obligatorio
        if (_productoController.text.trim().isEmpty) {
          return "Debe especificar el producto para el registro";
        }
        return _validarRangosTermicos();

      case "vincular":
        // Vincular solo necesita Código y Password (ya validados arriba)
        return null;

      case "entregar":
        // Entregar necesita el nombre del OPA (el emisor)
        if (_nombreOpaController.text.trim().isEmpty) {
          return "El nombre del OPA emisor es obligatorio para la entrega";
        }
        return null;

      default:
        return "Error de contexto: Acción no identificada";
    }
  }

  /// Validación modular de integridad térmica
  String? _validarRangosTermicos() {
    final double? min =
        double.tryParse(_tempMinController.text.replaceAll(',', '.'));
    final double? max =
        double.tryParse(_tempMaxController.text.replaceAll(',', '.'));

    if (min == null || max == null) {
      return "Las temperaturas deben ser números";
    }
    if (min > max) {
      return "Mínimo no puede ser mayor al máximo";
    }
    if (min == max) {
      return "Debe existir un rango operativo (Min ≠ Max)";
    }
    if (min < -50.0 || max > 100.0) {
      return "Rango fuera de límites del sensor (-50°C a 100°C)";
    }
    if (_passwordLoteController.text.length < 4) {
      return "Password debe tener min. 4 caracteres";
    }

    return null;
  }

  void _clearControllers() {
    _codigoController.clear();
    _productoController.clear();
    _tempMinController.clear();
    _tempMaxController.clear();
    _passwordLoteController.clear();
    _nombreOpaController.clear();
  }

  // --- INTERFAZ DE USUARIO PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // Ajustamos la posición para que no quede "pegado" abajo
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75, right: 8),
        child: GestureDetector(
          onTap: () {
            if (widget.role == "OPA") {
              _showFormModal(tipo: "crear");
            } else {
              _showActionMenu();
            }
          },
          child: Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2374A6), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2374A6).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Icon(
              widget.role == "OPT"
                  ? Icons.qr_code_scanner_rounded
                  : Icons.add_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF3B82F6),
        onRefresh: () async => _loadData(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildModernAppBar(),
            SliverToBoxAdapter(child: _buildSystemStatsHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              sliver: FutureBuilder<List<Lote>>(
                future: _futureLotes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: _buildErrorState(snapshot.error.toString()),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState());
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildIndustrialLoteCard(snapshot.data![index]),
                      childCount: snapshot.data!.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS COMPONENTES ---

  Widget _buildModernAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF1F5F9),
      elevation: 0,
      centerTitle: false,
      title: Text(
        'COMMAND CENTER',
        style: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: const Color(0xFF0F172A),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics_outlined, color: Color(0xFF3B82F6)),
          onPressed: () {},
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildSystemStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat("ACTIVOS", "12", const Color(0xFF3B82F6)),
          _buildDivider(),
          _buildQuickStat("ALERTAS", "02", const Color(0xFFEF4444)),
          _buildDivider(),
          _buildQuickStat("NODOS", "ONLINE", const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
      height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.2));

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.robotoMono(
              color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildIndustrialLoteCard(Lote lote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: lote.colorEstado.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    LoteDetailScreen(token: widget.token, loteId: lote.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatusIndicator(lote),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lote.codigoLote,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.robotoMono(
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildMiniBadge(lote),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lote.producto.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLinearProgress(lote),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Lote lote) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: lote.colorEstado.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.sensors, color: lote.colorEstado, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          "${lote.promedioTemperatura.toStringAsFixed(1)}°C",
          style: GoogleFonts.orbitron(
            color: const Color(0xFF0F172A),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(Lote lote) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: lote.colorEstado.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        lote.estadoActual,
        style: TextStyle(
            color: lote.colorEstado, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildLinearProgress(Lote lote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("INTEGRIDAD TÉRMICA",
                style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 8,
                    fontWeight: FontWeight.bold)),
            Text(lote.entregado ? "ENTREGADO" : "EN TRÁNSITO",
                style: TextStyle(
                    color: lote.entregado
                        ? const Color(0xFF10B981)
                        : const Color(0xFF3B82F6),
                    fontSize: 8,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: lote.entregado ? 1.0 : 0.65,
            backgroundColor: const Color(0xFFE2E8F0),
            color: lote.colorEstado,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 60, color: Color(0xFFEF4444)),
            const SizedBox(height: 20),
            Text(
              "ERROR DE COMUNICACIÓN",
              style: GoogleFonts.orbitron(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: GoogleFonts.inter(
                  color: const Color(0xFF64748B), fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("REINTENTAR ENLACE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 50, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text("SIN FLUJOS DE DATOS",
              style: GoogleFonts.robotoMono(
                  color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- MODALES DE ACCIÓN ---

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              Text("GESTIÓN DE LOGÍSTICA",
                  style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF64748B))),
              const SizedBox(height: 20),

              // 1. OPCIÓN CREAR
              if (widget.role == "admin" || widget.role == "OPA")
                _buildMenuOption(
                  icon: Icons.add_box_rounded,
                  label: "CREAR NUEVO LOTE",
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    // <--- CAMBIADO AQUÍ
                    Navigator.pop(context);
                    _showFormModal(tipo: "crear");
                  },
                ),

              // 2. OPCIÓN VINCULAR
              if (widget.role == "OPT")
                _buildMenuOption(
                  icon: Icons.link_rounded,
                  label: "VINCULAR CUSTODIA",
                  color: const Color(0xFF10B981),
                  onTap: () {
                    // <--- CAMBIADO AQUÍ
                    Navigator.pop(context);
                    _showFormModal(tipo: "vincular");
                  },
                ),

              // 3. OPCIÓN ENTREGAR
              if (widget.role == "admin" || widget.role == "OPT")
                _buildMenuOption(
                  icon: Icons.domain_verification_rounded,
                  label: "MARCAR COMO ENTREGADO",
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.pop(context); // Cierra el menú de Drive
                    _showFormModal(
                        tipo: "entregar"); // ABRE EL FORMULARIO DE ENTREGA
                  },
                ),

              const SizedBox(height: 10),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      size: 30, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

// --- MOTOR DE FORMULARIOS INDUSTRIALES ---
  // --- MOTOR DE FORMULARIOS DINÁMICO ---
  void _showFormModal({required String tipo}) {
    // Limpiamos controladores antes de abrir para que no haya datos viejos
    _currentFormType = tipo; // <--- Seteamos el contexto antes de validar
    _clearControllers();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text(
                tipo == "crear"
                    ? "NUEVO DESPACHO"
                    : (tipo == "vincular"
                        ? "MONITOREAR UNIDAD"
                        : "CONFIRMAR ENTREGA"),
                style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 24),

              // CAMPO 1: Código o Nombre del Lote
              _buildModernField(
                  controller: _codigoController,
                  label:
                      tipo == "entregar" ? "NOMBRE DEL LOTE" : "CÓDIGO DE LOTE",
                  icon: tipo == "entregar"
                      ? Icons.label_important_rounded
                      : Icons.qr_code_scanner_rounded),
              const SizedBox(height: 16),

              // CAMPO 2: Producto (Crear/Vincular) o Nombre del OPA (Entrega)
              _buildModernField(
                  controller: (tipo == "entregar" || tipo == "vincular")
                      ? _nombreOpaController
                      : _productoController,
                  label: (tipo == "entregar" || tipo == "vincular")
                      ? "NOMBRE DEL OPA (EMISOR)"
                      : "PRODUCTO / CARGA",
                  icon: (tipo == "entregar" || tipo == "vincular")
                      ? Icons.person_pin_rounded
                      : Icons.inventory_2_outlined),

              const SizedBox(height: 16),

              // CAMPO 3: Temperaturas (Solo para Crear/Vincular) O Contraseña (Para todos)
              if (tipo != "entregar") ...[
                Row(
                  children: [
                    Expanded(
                        child: _buildModernField(
                            controller: _tempMinController,
                            label: "MIN °C",
                            icon: Icons.ac_unit_rounded,
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildModernField(
                            controller: _tempMaxController,
                            label: "MAX °C",
                            icon: Icons.wb_sunny_rounded,
                            isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // NUEVO CAMPO: CONTRASEÑA (Obligatorio en Crear y Entregar)
              _buildModernField(
                  controller: _passwordLoteController,
                  label: "CONTRASEÑA DE SEGURIDAD",
                  icon: Icons.lock_outline_rounded,
                  isPassword: true),

              const SizedBox(height: 32),

              // BOTÓN DE ACCIÓN
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tipo == "entregar"
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),

// Busca el bloque del ElevatedButton en _showFormModal y reemplázalo por este:

                  onPressed: _isLoadingAction
                      ? null
                      : () async {
                          final error = _validarFormularioLote();
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.redAccent));
                            return;
                          }

                          setState(() => _isLoadingAction = true);

                          try {
                            final String codigo = _codigoController.text.trim();
                            final String password =
                                _passwordLoteController.text.trim();

                            if (tipo == "crear") {
                              // EXPLICACIÓN: Cambiamos 'temp_min_esperada' por 'temp_min_ideal'
                              // para que coincida exactamente con schemas.py (LoteBase)
                              final double min = double.parse(
                                  _tempMinController.text.replaceAll(',', '.'));
                              final double max = double.parse(
                                  _tempMaxController.text.replaceAll(',', '.'));

                              await _loteService.createLote(widget.token, {
                                "codigo_lote": codigo,
                                "producto": _productoController.text.trim(),
                                "temp_min_ideal": min, // <--- LLAVE CORREGIDA
                                "temp_max_ideal": max, // <--- LLAVE CORREGIDA
                                "password_lote": password,
                              });
                            } else if (tipo == "vincular") {
                              // EXPLICACIÓN: Tu schema 'LoteVincular' EXIGE 'nombre_opa'.
                              // Si no lo envías, el backend arroja error 422.
                              await _loteService.vincularLote(widget.token, {
                                "nombre_opa": _nombreOpaController.text
                                    .trim(), // <--- CAMPO AÑADIDO
                                "codigo_lote": codigo,
                                "password_lote": password,
                              });
                            } else if (tipo == "entregar") {
                              await _loteService.entregarLote(widget.token, {
                                "nombre_opa": _nombreOpaController.text.trim(),
                                "codigo_lote": codigo,
                                "password_lote": password,
                              });
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _loadData();
                              _clearControllers();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("OPERACIÓN PROCESADA CON ÉXITO"),
                                      backgroundColor: Color(0xFF10B981)));
                            }
                          } catch (e) {
                            if (mounted) {
                              // Mostramos el error real que viene del servicio para debuguear mejor
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("ERROR: $e"),
                                      backgroundColor: Colors.red));
                            }
                          } finally {
                            if (mounted)
                              setState(() => _isLoadingAction = false);
                          }
                        },

                  child: _isLoadingAction
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          tipo == "entregar"
                              ? "FINALIZAR ENTREGA"
                              : "CONFIRMAR REGISTRO",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
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
    bool isNumber = false,
    bool isPassword = false, // <--- Nueva propiedad
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword, // <--- Oculta el texto si es password
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
      onTap: onTap,
    );
  }
}
