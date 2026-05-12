// File: lib/screens/crop_recommendation/crop_recommendation_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'soil_mineral_form_screen.dart';
import 'lab_report_upload_screen.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/main_nav_controller.dart';
import '../../routes/app_routes.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen>
    with TickerProviderStateMixin {
  final AuthController _auth = Get.find<AuthController>();

  void _backToDashboard() {
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().goToDashboardRoot();
      return;
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _dark    = Color(0xFF1A2F0E);
  static const _mid     = Color(0xFF4A7C2C);
  static const _accent  = Color(0xFF6BAE3E);
  static const _light   = Color(0xFF8FAF7A);
  static const _bg      = Color(0xFFF4F8F0);
  static const _bgCard  = Color(0xFFFFFFFF);
  static const _border  = Color(0xFFDFEDD3);
  static const _surface = Color(0xFFEDF4E5);
  static const _textSub = Color(0xFF7A8F6E);

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _enterCtrl;
  late AnimationController _headerCtrl;
  late List<AnimationController> _cardCtrls;

  late Animation<double> _fadeIn;
  late Animation<Offset> _headerSlide;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterCtrl.forward();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _headerCtrl, curve: Curves.easeOutQuart));
    _headerCtrl.forward();

    // 3 option cards + info box = 4 staggered items
    _cardCtrls = List.generate(
      4,
      (i) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 700)),
    );
    _cardFades = _cardCtrls
        .map((c) => Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _cardSlides = _cardCtrls
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: c, curve: Curves.easeOutQuart)))
        .toList();

    for (var i = 0; i < _cardCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 100), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _headerCtrl.dispose();
    for (final c in _cardCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideTransition(
                      position: _headerSlide,
                      child: _buildHeroCard(),
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Choose Input Method'),
                    const SizedBox(height: 14),

                    // ── Option 1: Upload Lab Report (NOW ENABLED) ──────────
                    _animCard(
                      0,
                      _buildOptionCard(
                        title: 'Upload Lab Report',
                        subtitle:
                            'Scan or photo your soil test certificate — we\'ll read the values automatically',
                        icon: Icons.document_scanner_rounded,
                        color: const Color(0xFF0284C7),
                        isEnabled: true,
                        tag: 'Auto-Fill',
                        tagColor: const Color(0xFF0284C7),
                        tagBg: const Color(0xFFE0F2FE),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LabReportUploadScreen(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Option 2: Weather-Based (still disabled) ───────────
                    _animCard(
                      1,
                      _buildOptionCard(
                        title: 'Weather-Based Forecast',
                        subtitle:
                            'Auto-detect local weather and get season-matched crop advice',
                        icon: Icons.wb_cloudy_rounded,
                        color: _light,
                        isEnabled: true,
                        tag: 'New',
                        tagColor: const Color(0xFFD97706),
                        tagBg: const Color(0xFFFEF3C7),
                        onTap: () {
                          if (_auth.needsLocationSetup || !_auth.hasLocation) {
                            Get.toNamed(
                              AppRoutes.locationSetup,
                              arguments: {
                                'next': AppRoutes.weatherBasedCrop,
                                'mode': 'off',
                              },
                            );
                            return;
                          }
                          Navigator.of(context)
                              .pushNamed(AppRoutes.weatherBasedCrop);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Option 3: Manual Entry (enabled) ──────────────────
                    _animCard(
                      2,
                      _buildOptionCard(
                        title: 'Enter Soil Data Manually',
                        subtitle:
                            'Fill in nitrogen, phosphorus, potassium & other minerals yourself',
                        icon: Icons.science_rounded,
                        color: _mid,
                        isEnabled: true,
                        tag: 'Available Now',
                        tagColor: const Color(0xFF16A34A),
                        tagBg: const Color(0xFFDCFCE7),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SoilMineralFormScreen(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
                    _animCard(3, _buildInfoBanner()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _bgCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: _dark,
        ),
        onPressed: _backToDashboard,
        tooltip: 'Back to Dashboard',
      ),
      title: const Text(
        'Crop Recommendations',
        style: TextStyle(
          color: _dark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _dark.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18, top: -18,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            right: 20, bottom: -10,
            child: Container(
              width: 55, height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 14, color: Color(0xFF9DE05A)),
                    SizedBox(width: 6),
                    Text(
                      'AI-Powered Analysis',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9DE05A),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'What should\nyou grow next?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tell us about your soil and we\'ll recommend the best crops for your land and season.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _heroStat('15+', 'Crops'),
                  _heroDivider(),
                  _heroStat('3', 'Methods'),
                  _heroDivider(),
                  _heroStat('98%', 'Accuracy'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _heroDivider() =>
      Container(width: 1, height: 28, color: Colors.white.withOpacity(0.12));

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_dark, _mid],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _dark,
              letterSpacing: -0.2,
            )),
      ],
    );
  }

  // ── Option card ───────────────────────────────────────────────────────────
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEnabled ? color.withOpacity(0.3) : _border,
            width: isEnabled ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled
                  ? color.withOpacity(0.07)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isEnabled ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isEnabled
                    ? color.withOpacity(0.1)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isEnabled
                        ? color.withOpacity(0.2)
                        : const Color(0xFFE8E8E8)),
              ),
              child: Icon(icon,
                  size: 24,
                  color: isEnabled ? color : const Color(0xFFBBBBBB)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isEnabled
                                ? _dark
                                : const Color(0xFFBBBBBB),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isEnabled
                              ? tagBg
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isEnabled
                                ? tagColor
                                : const Color(0xFFBBBBBB),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isEnabled ? _textSub : const Color(0xFFCCCCCC),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: isEnabled ? _surface : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isEnabled ? _mid : const Color(0xFFCCCCCC)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info banner ───────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_rounded,
                color: Color(0xFF0284C7), size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather-based forecast coming soon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0C4A6E),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Auto weather detection is under development. Lab report scanning and manual soil entry are both available now.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF0369A1), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animCard(int i, Widget child) => FadeTransition(
        opacity: _cardFades[i],
        child: SlideTransition(position: _cardSlides[i], child: child),
      );
}