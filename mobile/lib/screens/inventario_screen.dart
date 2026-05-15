import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
enum ProductStatus { bueno, alerta, critico }

class Product {
  final String name;
  final String lot;
  final int quantity;
  final double temperature;
  final ProductStatus status;
  final Color bannerColor;
  final Color accentColor;
  final IconData bannerIcon;

  const Product({
    required this.name,
    required this.lot,
    required this.quantity,
    required this.temperature,
    required this.status,
    required this.bannerColor,
    required this.accentColor,
    required this.bannerIcon,
  });
}

// ─── InventarioPage ───────────────────────────────────────────────────────────
class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  static const Color bgColor = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color titleColor = Color(0xFF1C1C1E);
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color appleBlue = Color(0xFF007AFF);
  static const Color appleGreen = Color(0xFF30D158);
  static const Color appleOrange = Color(0xFFFF9F0A);
  static const Color appleRed = Color(0xFFFF453A);

  // Jhonatan esta es la parte donde tendras que implementar lo logica, yo puse datos de ejemplo para mostrar la interfaz, pero tu debes
  //conectar con el backend para traer los datos reales de los productos y sus estados.
  //Puedes usar la clase Product como modelo para representar cada producto en el inventario, y luego llenar la lista _allProducts con los datos que recibas del backend.
  //Asegúrate de actualizar el estado de la aplicación cada vez que recibas nuevos datos para que la interfaz se actualice correctamente.

  static const _allProducts = [
    Product(
      name: 'Carne Refrigerada',
      lot: 'LOT-Z67DS1EE',
      quantity: 451,
      temperature: -1.7,
      status: ProductStatus.bueno,
      bannerColor: Color(0xFFFFEEED),
      accentColor: appleRed,
      bannerIcon: Icons.set_meal_rounded,
    ),
    Product(
      name: 'Lácteos Frescos',
      lot: 'LOT-K9AG55H7',
      quantity: 364,
      temperature: -0.9,
      status: ProductStatus.bueno,
      bannerColor: Color(0xFFEDF9F0),
      accentColor: appleGreen,
      bannerIcon: Icons.water_drop_rounded,
    ),
    Product(
      name: 'Pescado Congelado',
      lot: 'LOT-KEUH0SK0',
      quantity: 222,
      temperature: 8.5,
      status: ProductStatus.critico,
      bannerColor: Color(0xFFFFF0EE),
      accentColor: appleRed,
      bannerIcon: Icons.set_meal_outlined,
    ),
    Product(
      name: 'Verduras Frescas',
      lot: 'LOT-000PTPW',
      quantity: 538,
      temperature: -1.4,
      status: ProductStatus.bueno,
      bannerColor: Color(0xFFEAF3DE),
      accentColor: appleGreen,
      bannerIcon: Icons.eco_rounded,
    ),
    Product(
      name: 'Frutas Importadas',
      lot: 'LOT-FRU88XZ2',
      quantity: 190,
      temperature: 4.2,
      status: ProductStatus.alerta,
      bannerColor: Color(0xFFFFF4E5),
      accentColor: appleOrange,
      bannerIcon: Icons.apple_rounded,
    ),
    Product(
      name: 'Quesos Madurados',
      lot: 'LOT-QSM22KL9',
      quantity: 87,
      temperature: 2.1,
      status: ProductStatus.bueno,
      bannerColor: Color(0xFFFFFBED),
      accentColor: appleOrange,
      bannerIcon: Icons.bakery_dining_rounded,
    ),
    Product(
      name: 'Embutidos Premium',
      lot: 'LOT-EMB77PP1',
      quantity: 312,
      temperature: 0.5,
      status: ProductStatus.bueno,
      bannerColor: Color(0xFFFFEEED),
      accentColor: appleRed,
      bannerIcon: Icons.lunch_dining_rounded,
    ),
    Product(
      name: 'Helados y Postres',
      lot: 'LOT-HEL44RX8',
      quantity: 155,
      temperature: -14.3,
      status: ProductStatus.bueno,
      bannerColor: Color(0xFFE5F1FF),
      accentColor: appleBlue,
      bannerIcon: Icons.icecream_rounded,
    ),
  ];

  ProductStatus? _activeFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Product> get _filtered {
    return _allProducts.where((p) {
      final matchStatus = _activeFilter == null || p.status == _activeFilter;
      final matchSearch = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchStatus && matchSearch;
    }).toList();
  }

  int get _countBuenos =>
      _allProducts.where((p) => p.status == ProductStatus.bueno).length;
  int get _countAlerta =>
      _allProducts.where((p) => p.status == ProductStatus.alerta).length;
  int get _countCritico =>
      _allProducts.where((p) => p.status == ProductStatus.critico).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // Header: Título + subtítulo + back button
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
                              'Inventario',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.4,
                                color: titleColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Gestión de productos refrigerados',
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
                      // Back button (if pushed from HomeScreen)
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

              // Tarjetas de estado (Total, Buenos, Alerta, Crítico)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      _StatCard(
                        value: _allProducts.length.toString(),
                        label: 'Total',
                        textColor: titleColor,
                        bg: cardColor,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        value: _countBuenos.toString(),
                        label: 'Buenos',
                        textColor: Colors.white,
                        bg: appleGreen,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        value: _countAlerta.toString(),
                        label: 'Alerta',
                        textColor: Colors.white,
                        bg: appleOrange,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        value: _countCritico.toString(),
                        label: 'Crítico',
                        textColor: Colors.white,
                        bg: appleRed,
                      ),
                    ],
                  ),
                ),
              ),

              // Barra de busqueda
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: labelGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(
                              fontSize: 15,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Buscar producto...',
                              hintStyle: TextStyle(
                                color: Color(0xFFC7C7CC),
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 18,
                                color: labelGray,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Filter chips ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 17, 20, 0),
                    children: [
                      _FilterChip(
                        label: 'Todos',
                        isActive: _activeFilter == null,
                        onTap: () => setState(() => _activeFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Buenos',
                        isActive: _activeFilter == ProductStatus.bueno,
                        activeColor: appleGreen,
                        onTap: () =>
                            setState(() => _activeFilter = ProductStatus.bueno),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Alerta',
                        isActive: _activeFilter == ProductStatus.alerta,
                        activeColor: appleOrange,
                        onTap: () => setState(
                          () => _activeFilter = ProductStatus.alerta,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Crítico',
                        isActive: _activeFilter == ProductStatus.critico,
                        activeColor: appleRed,
                        onTap: () => setState(
                          () => _activeFilter = ProductStatus.critico,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Productos header + count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: Row(
                    children: [
                      const Text(
                        'Productos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: appleBlue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),

                        // Este muestra el número de productos que coinciden con el filtro de búsqueda y estado
                        child: Text(
                          '${_filtered.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: appleBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Productos lista
              _filtered.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: labelGray.withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Sin resultados',
                              style: TextStyle(
                                fontSize: 16,
                                color: labelGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            i == _filtered.length - 1 ? 32 : 12,
                          ),
                          child: _AnimatedProductCard(
                            index: i,
                            product: _filtered[i],
                          ),
                        ),
                        childCount: _filtered.length,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta de estadística (Total, Buenos, Alerta, Crítico)
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color bg;

  const _StatCard({
    required this.value,
    required this.label,
    required this.textColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.75),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filtro de estado (Todos, Buenos, Alerta, Crítico)
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.activeColor = const Color(0xFF007AFF),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            color: isActive ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ),
    );
  }
}

// Animacion de aparición para las tarjetas de producto
class _AnimatedProductCard extends StatefulWidget {
  final int index;
  final Product product;

  const _AnimatedProductCard({required this.index, required this.product});

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _ProductCard(product: widget.product),
      ),
    );
  }
}

// Product Card
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  static const Color titleColor = Color(0xFF1C1C1E);
  static const Color labelGray = Color(0xFF8E8E93);

  Widget _statusBadge() {
    late String text;
    late Color bg;
    late Color fg;

    switch (product.status) {
      case ProductStatus.bueno:
        text = 'Bueno';
        bg = const Color(0xFF30D158).withOpacity(0.12);
        fg = const Color(0xFF1A7A32);
        break;
      case ProductStatus.alerta:
        text = 'Alerta';
        bg = const Color(0xFFFF9F0A).withOpacity(0.12);
        fg = const Color(0xFF8A5200);
        break;
      case ProductStatus.critico:
        text = 'Crítico';
        bg = const Color(0xFFFF453A).withOpacity(0.12);
        fg = const Color(0xFF9B1208);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  IconData _statusIcon() {
    switch (product.status) {
      case ProductStatus.bueno:
        return Icons.inventory_2_rounded;
      case ProductStatus.alerta:
        return Icons.warning_amber_rounded;
      case ProductStatus.critico:
        return Icons.error_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCritical = product.status == ProductStatus.critico;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  color: product.bannerColor,
                  child: Center(
                    child: Icon(
                      product.bannerIcon,
                      size: 64,
                      color: product.accentColor.withOpacity(0.22),
                    ),
                  ),
                ),
                // Status badge top-right
                Positioned(top: 12, right: 14, child: _statusBadge()),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + name + lot
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: product.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _statusIcon(),
                        color: product.accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.lot,
                            style: const TextStyle(
                              fontSize: 12,
                              color: labelGray,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: labelGray.withOpacity(0.5),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF2F2F7)),
                const SizedBox(height: 14),

                // ── Meta grid 2×2 ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MetaTile(
                        icon: Icons.inventory_2_outlined,
                        label: 'Cantidad',
                        value: '${product.quantity} uds',
                        valueColor: titleColor,
                      ),
                    ),
                    Expanded(
                      child: _MetaTile(
                        icon: Icons.thermostat_rounded,
                        label: 'Temperatura',
                        value: '${product.temperature}°C',
                        valueColor: isCritical
                            ? const Color(0xFFFF453A)
                            : titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Meta tile ────────────────────────────────────────────────────────────────
class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8E8E93),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
