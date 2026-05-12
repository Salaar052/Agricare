// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../api/auth_service.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import 'admin_farmers_screen.dart';
import 'admin_chat_monitor_screen.dart';
import 'admin_marketplace_pending_screen.dart';
import 'admin_profile_screen.dart';
import '../news/admin_news_screen.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
class _P {
  static const bg       = Color(0xFFF3F8EF);
  static const card     = Colors.white;
  static const dark     = Color(0xFF1A2F0E);
  static const mid      = Color(0xFF4A7C2C);
  static const soft     = Color(0xFF6BAE3E);
  static const surface  = Color(0xFFEAF4E5);
  static const border   = Color(0xFFD4E8C8);
  static const sub      = Color(0xFF7A8F6E);
  static const white    = Colors.white;
}

// ── Card data ─────────────────────────────────────────────────────────────────
class _CardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color accentBg;
  final VoidCallback onTap;

  const _CardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.onTap,
  });
}

// ── Main screen ───────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final AuthController _auth   = Get.find<AuthController>();
  final AuthService   _service = AuthService();

  // stagger
  late AnimationController _stagger;
  late List<Animation<double>>  _fades;
  late List<Animation<Offset>>  _slides;

  // header
  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade = CurvedAnimation(
        parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _headerCtrl, curve: Curves.easeOutQuart));
    _headerCtrl.forward();

    _stagger = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fades = List.generate(5, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _stagger,
          curve: Interval(s, (s + 0.32).clamp(0, 1), curve: Curves.easeOut)));
    });
    _slides = List.generate(5, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _stagger,
              curve: Interval(s, (s + 0.32).clamp(0, 1),
                  curve: Curves.easeOutQuart)));
    });

    Future.microtask(() {
      if (mounted) _stagger.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _stagger.dispose();
    super.dispose();
  }

  void _go(Widget page) => Get.to(
        () => page,
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );

  @override
  Widget build(BuildContext context) {
    final cards = <_CardData>[
      _CardData(
        title: 'Admin Profile',
        subtitle: 'Account & settings',
        icon: Icons.verified_user_rounded,
        accent: _P.mid,
        accentBg: _P.surface,
        onTap: () => _go(const AdminProfileScreen()),
      ),
      _CardData(
        title: 'News',
        subtitle: 'Create & publish',
        icon: Icons.article_rounded,
        accent: const Color(0xFF0284C7),
        accentBg: const Color(0xFFE0F2FE),
        onTap: () => _go(const AdminNewsScreen()),
      ),
      _CardData(
        title: 'Farmers',
        subtitle: 'Users & sellers',
        icon: Icons.groups_rounded,
        accent: const Color(0xFF059669),
        accentBg: const Color(0xFFD1FAE5),
        onTap: () => _go(const AdminFarmersScreen()),
      ),
      _CardData(
        title: 'Marketplace',
        subtitle: 'Listings & approvals',
        icon: Icons.storefront_rounded,
        accent: const Color(0xFFD97706),
        accentBg: const Color(0xFFFEF3C7),
        onTap: () => _go(const AdminMarketplacePendingScreen()),
      ),
      _CardData(
        title: 'Community Chat',
        subtitle: 'Groups & members',
        icon: Icons.forum_rounded,
        accent: const Color(0xFF7C3AED),
        accentBg: const Color(0xFFEDE9FE),
        onTap: () => _go(const AdminChatMonitorScreen()),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _P.bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome card ──────────────────────────────────────
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _buildWelcomeCard(),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ── Section label ─────────────────────────────────────
                    FadeTransition(
                      opacity: _headerFade,
                      child: _sectionLabel('Quick Access'),
                    ),
                    const SizedBox(height: 14),

                    // ── Grid ──────────────────────────────────────────────
                    _buildGrid(cards),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver App Bar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor: _P.dark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A2F0E), Color(0xFF3A6B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _P.soft.withOpacity(0.2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () async {
              await _service.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
    );
  }

  // ── Welcome card ────────────────────────────────────────────────────────────
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: _P.mid.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3A6B22), Color(0xFF6BAE3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(() {
              final name  = _auth.username.value.trim();
              final email = _auth.email.value.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Welcome back' : 'Welcome, $name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _P.dark,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email.isEmpty ? 'Administrator' : email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _P.sub,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 10),
          // Admin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: _P.soft,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _P.mid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Row(
        children: [
          Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_P.dark, _P.mid],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _P.dark,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );

  // ── Grid ────────────────────────────────────────────────────────────────────
  // Uses a Column of Rows to avoid AspectRatio overflow.
  // Card height is fixed at 148dp — enough for icon + title + subtitle with
  // comfortable padding, no overflow on any density.
  Widget _buildGrid(List<_CardData> cards) {
    const cardHeight = 148.0;
    const gap        = 14.0;
    final rows       = (cards.length / 2).ceil();

    return Column(
      children: List.generate(rows, (r) {
        final left  = r * 2;
        final right = r * 2 + 1;
        return Padding(
          padding: EdgeInsets.only(bottom: r < rows - 1 ? gap : 0),
          child: Row(
            children: [
              Expanded(
                child: FadeTransition(
                  opacity: _fades[left],
                  child: SlideTransition(
                    position: _slides[left],
                    child: _DashCard(
                        data: cards[left], height: cardHeight),
                  ),
                ),
              ),
              const SizedBox(width: gap),
              Expanded(
                child: right < cards.length
                    ? FadeTransition(
                        opacity: _fades[right],
                        child: SlideTransition(
                          position: _slides[right],
                          child: _DashCard(
                              data: cards[right], height: cardHeight),
                        ),
                      )
                    : const SizedBox(), // odd card — leave right cell empty
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Individual card widget ────────────────────────────────────────────────────
class _DashCard extends StatefulWidget {
  final _CardData data;
  final double    height;

  const _DashCard({required this.data, required this.height});

  @override
  State<_DashCard> createState() => _DashCardState();
}

class _DashCardState extends State<_DashCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown:    (_) => setState(() => _pressed = true),
      onTapUp:      (_) => setState(() => _pressed = false),
      onTapCancel:  ()  => setState(() => _pressed = false),
      onTap:        d.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          height: widget.height,
          child: Container(
            decoration: BoxDecoration(
              color: _P.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.border),
              boxShadow: [
                BoxShadow(
                  color: d.accent.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Icon box ────────────────────────────────────────────
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: d.accentBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(d.icon, size: 24, color: d.accent),
                  ),
                  // ── Text ────────────────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _P.dark,
                          letterSpacing: -0.2,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d.subtitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: _P.sub,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: d.accentBg,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: d.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}