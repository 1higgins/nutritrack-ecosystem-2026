import 'package:flutter/material.dart';
import 'registro_screen.dart';
import 'inventario_screen.dart';

class TemperaturaPage extends StatelessWidget {
  const TemperaturaPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Temperatura')),
    body: const Center(child: Text('Monitoreo de temperatura')),
  );
}

// ─── HomeScreen ───────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final String username;
  const HomeScreen({super.key, this.username = 'Usuario'});

  static const Color appleBlue = Color(0xFF007AFF);
  static const Color bgColor = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color labelGray = Color(0xFF8E8E93);
  static const Color titleColor = Color(0xFF1C1C1E);

  static const _chips = [
    _ChipData(
      icon: Icons.thermostat_rounded,
      label: 'Temperatura',
      iconColor: Color(0xFFFF453A),
    ),
    _ChipData(
      icon: Icons.inventory_2_rounded,
      label: 'Lotes',
      iconColor: Color(0xFFFF9F0A),
    ),
    _ChipData(
      icon: Icons.store_rounded,
      label: 'Inventario',
      iconColor: Color(0xFF007AFF),
    ),
    _ChipData(
      icon: Icons.bar_chart_rounded,
      label: 'Reportes',
      iconColor: Color(0xFFBF5AF2),
    ),
  ];

  static const _cards = [
    _CardData(
      imagePlaceholderColor: Color(0xFFFFEEED),
      icon: Icons.thermostat_rounded,
      iconColor: Color(0xFFFF453A),
      title: 'Temperatura',
      subtitle: 'Monitoreo en tiempo real',
      destination: _Dest.temperatura,
    ),
    _CardData(
      imagePlaceholderColor: Color(0xFFFFF4E5),
      icon: Icons.inventory_2_rounded,
      iconColor: Color(0xFFFF9F0A),
      title: 'Registrar Lotes',
      subtitle: 'Agrega nuevos lotes',
      destination: _Dest.lotes,
    ),
    _CardData(
      imagePlaceholderColor: Color(0xFFE5F1FF),
      icon: Icons.store_rounded,
      iconColor: Color(0xFF007AFF),
      title: 'Inventario',
      subtitle: 'Gestiona tu stock',
      destination: _Dest.inventario,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hola de nuevo,',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: labelGray,
                                  letterSpacing: -0.3,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.4,
                                  color: titleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: appleBlue.withOpacity(0.12),
                          ),
                          child: Center(
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: appleBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Scrollable chips ─────────────────────────────────
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _chips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _QuickChip(data: _chips[i]),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Section label ────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Accesos rápidos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: titleColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── Animated cards list ──────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    i == _cards.length - 1 ? 24 : 14,
                  ),
                  child: _AnimatedCard(index: i, data: _cards[i]),
                ),
                childCount: _cards.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated wrapper ─────────────────────────────────────────────────────────
class _AnimatedCard extends StatefulWidget {
  final int index;
  final _CardData data;
  const _AnimatedCard({required this.index, required this.data});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
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

    // stagger each card by 80ms
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
        child: _DashCard(data: widget.data),
      ),
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────
class _ChipData {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _ChipData({
    required this.icon,
    required this.label,
    required this.iconColor,
  });
}

class _QuickChip extends StatelessWidget {
  final _ChipData data;
  const _QuickChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: HomeScreen.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 16, color: data.iconColor),
            const SizedBox(width: 7),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                color: HomeScreen.titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card data & dest ─────────────────────────────────────────────────────────
enum _Dest { temperatura, lotes, inventario }

class _CardData {
  final Color imagePlaceholderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final _Dest destination;
  const _CardData({
    required this.imagePlaceholderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.destination,
  });
}

// ─── Dashboard card (full width) ─────────────────────────────────────────────
class _DashCard extends StatelessWidget {
  final _CardData data;
  const _DashCard({required this.data});

  void _navigate(BuildContext context) {
    Widget page;
    switch (data.destination) {
      case _Dest.temperatura:
        page = const TemperaturaPage();
        break;
      case _Dest.lotes:
        page = const LotesPage();
        break;
      case _Dest.inventario:
        page = const InventarioPage();
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: HomeScreen.cardColor,
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
            // Image area — full width, taller now that card is wide
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                height: 150,
                color: data.imagePlaceholderColor,
                // Replace with: Image.asset('assets/images/xxx.png', fit: BoxFit.cover)
                child: Center(
                  child: Icon(
                    data.icon,
                    size: 64,
                    color: data.iconColor.withOpacity(0.22),
                  ),
                ),
              ),
            ),

            // Bottom: icon + text + chevron
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: data.iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, color: data.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: HomeScreen.titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          data.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: HomeScreen.labelGray,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: HomeScreen.labelGray.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
