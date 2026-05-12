// ============================================
// FILE 2: lib/screens/marketplace/marketplace_welcome_screen.dart
// Welcome screen when no account exists
// ============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/main_nav_controller.dart';
import '../../routes/app_routes.dart';

class MarketplaceWelcomeScreen extends StatefulWidget {
  const MarketplaceWelcomeScreen({super.key});

  @override
  State<MarketplaceWelcomeScreen> createState() =>
      _MarketplaceWelcomeScreenState();
}

class _MarketplaceWelcomeScreenState extends State<MarketplaceWelcomeScreen>
    with TickerProviderStateMixin {

  void _backToDashboard() {
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().goToDashboardRoot();
      return;
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }

  // ── Screen enter animation ──
  late AnimationController _enterController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Hero icon float + pulse ──
  late AnimationController _iconController;
  late Animation<double> _iconFloat;
  late Animation<double> _iconScale;

  // ── Outer ring ripple ──
  late AnimationController _rippleController;
  late Animation<double> _rippleAnim;

  // ── Staggered benefit items ──
  late AnimationController _staggerController;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;

  @override
  void initState() {
    super.initState();

    // ── 1. Screen enter ──
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic));
    _enterController.forward();

    // ── 2. Icon float + breathe ──
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _iconFloat = Tween<double>(begin: 0.0, end: -7.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
    _iconScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    // ── 3. Ripple ring ──
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _rippleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // ── 4. Staggered benefit items ──
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _itemFades = List.generate(3, (i) {
      final start = 0.2 + i * 0.2;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, (start + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
    });

    _itemSlides = List.generate(3, (i) {
      final start = 0.2 + i * 0.2;
      return Tween<Offset>(
        begin: const Offset(0.15, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, (start + 0.3).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ),
      );
    });

    // Delay stagger until enter anim is halfway
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _iconController.dispose();
    _rippleController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D5016), size: 20),
          onPressed: _backToDashboard,
        ),
        title: const Text(
          'Marketplace',
          style: TextStyle(
            color: Color(0xFF2D5016),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8F0E4)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 44),

                // ── Animated Hero Icon ──
                AnimatedBuilder(
                  animation: Listenable.merge([_iconController, _rippleController]),
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(0, _iconFloat.value),
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple ring
                              Opacity(
                                opacity: (1.0 - _rippleAnim.value).clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.85 + (_rippleAnim.value * 0.4),
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF4A7C2C).withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Outer static ring
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF4A7C2C).withOpacity(0.07),
                                ),
                              ),
                              // Mid ring
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF4A7C2C).withOpacity(0.11),
                                ),
                              ),
                              // Inner gradient circle
                              Container(
                                width: 82,
                                height: 82,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF5A9233), Color(0xFF2D5016)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  'Your Farm, Your Market',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D5016),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Buy, sell, and connect with fellow farmers\nin one seamless marketplace.',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF6B8F5E),
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── Benefits Card with staggered items ──
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE3EFD9), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D5016).withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_rounded,
                              color: Color(0xFF4A7C2C), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Why Join AgriCare Market?',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D5016),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Divider(color: Color(0xFFE8F0E4), thickness: 1),
                      const SizedBox(height: 14),

                      // Staggered item 1
                      FadeTransition(
                        opacity: _itemFades[0],
                        child: SlideTransition(
                          position: _itemSlides[0],
                          child: const _BenefitItem(
                            icon: Icons.trending_up_rounded,
                            title: 'Sell Your Produce',
                            subtitle: 'List and manage your farm products easily',
                            color: Color(0xFF2D5016),
                            bgColor: Color(0xFFEAF4E1),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Staggered item 2
                      FadeTransition(
                        opacity: _itemFades[1],
                        child: SlideTransition(
                          position: _itemSlides[1],
                          child: const _BenefitItem(
                            icon: Icons.shopping_bag_rounded,
                            title: 'Buy Farm Supplies',
                            subtitle: 'Access seeds, tools and more at great prices',
                            color: Color(0xFF4A7C2C),
                            bgColor: Color(0xFFF0F7EB),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Staggered item 3
                      FadeTransition(
                        opacity: _itemFades[2],
                        child: SlideTransition(
                          position: _itemSlides[2],
                          child: const _BenefitItem(
                            icon: Icons.people_alt_rounded,
                            title: 'Connect with Farmers',
                            subtitle: 'Build your agri network across the region',
                            color: Color(0xFF5A9233),
                            bgColor: Color(0xFFF4F9F0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Create Account Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/marketplace-register');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7C2C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 19),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Benefit Item
// ──────────────────────────────────────────
class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5016),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF7A9B6A),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}