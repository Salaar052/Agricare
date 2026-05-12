// lib/screens/marketplace/marketplace_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/main_nav_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/marketplace_service.dart';
import '../../controllers/auth_controller.dart';
import 'your_listings_screen.dart';
import 'saved_items_screen.dart';
import '../../api/api_config.dart';
import 'view_seller_profile_screen.dart';

class MarketplaceProfileScreen extends StatefulWidget {
  const MarketplaceProfileScreen({super.key});

  @override
  State<MarketplaceProfileScreen> createState() =>
      _MarketplaceProfileScreenState();
}

class _MarketplaceProfileScreenState extends State<MarketplaceProfileScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;
  final AuthController _authController = Get.find<AuthController>();

  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  int _listingsCount = 0;

  late AnimationController _enterController;
  late AnimationController _headerController;
  late AnimationController _staggerController;

  late Animation<double> _fadeBg;
  late Animation<double> _avatarScale;
  late Animation<Offset> _headerSlide;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  // ── Design tokens — matched to MarketplaceMainScreen ──────────────────────
  static const Color _primary    = Color(0xFF2D5016); // main screen primary
  static const Color _secondary  = Color(0xFF4A7C2C); // main screen secondary
  static const Color _bg         = Color(0xFFF8FBF8); // main screen background
  static const Color _card       = Colors.white;
  static const Color _border     = Color(0xFFE0EED4); // main screen border
  static const Color _surface    = Color(0xFFF1F5EF); // main screen surface tint
  static const Color _textDark   = Color(0xFF2D5016); // main screen title color
  static const Color _textMid    = Color(0xFF4A7C2C);
  static const Color _textMuted  = Colors.grey;

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);
    _loadProfile();

    _enterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeBg = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _enterController.forward();

    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _avatarScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.elasticOut));
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _headerController, curve: Curves.easeOutQuart));
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _headerController.forward();
    });

    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardFades = List.generate(4, (i) {
      final s = (i * 0.14).clamp(0.0, 0.86);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _staggerController,
          curve:
              Interval(s, (s + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut)));
    });
    _cardSlides = List.generate(4, (i) {
      final s = (i * 0.14).clamp(0.0, 0.86);
      return Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(s, (s + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOutQuart)));
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _headerController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _marketplaceService.getMyProfile();
      final listings = await _marketplaceService.getMyListings();
      setState(() {
        _profile = profile;
        _listingsCount = listings.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load profile');
    }
  }

  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        }
        if (Get.isRegistered<MainNavController>()) {
          Get.find<MainNavController>().navigate(AppRoutes.dashboard);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: FadeTransition(
          opacity: _fadeBg,
          child: _isLoading ? _buildLoadingState() : _buildBody(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // BODY
  // ─────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildProfileHeader()),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _animatedCard(0, _buildQuickActions()),
                    const SizedBox(height: 10),
                    _animatedCard(1, _buildSellingSection()),
                    const SizedBox(height: 10),
                    _animatedCard(2, _buildAccountSection()),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // TOP BAR — mirrors MarketplaceMainScreen header exactly
  // ─────────────────────────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF2D5016), size: 20),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }
                if (Get.isRegistered<MainNavController>()) {
                  Get.find<MainNavController>().navigate(AppRoutes.dashboard);
                  return;
                }
                Get.offAllNamed(AppRoutes.dashboard);
              },
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5016)),
                ),
                Text(
                  'Manage your store & listings',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // PROFILE HEADER CARD (below top bar)
  // ─────────────────────────────────────────
  Widget _buildProfileHeader() {
    return SlideTransition(
      position: _headerSlide,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            ScaleTransition(
              scale: _avatarScale,
              child: _buildAvatar(),
            ),

            const SizedBox(width: 16),

            // Name + view profile button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile?['shopName'] ?? _authController.username.value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5016),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      final id = _profile?['_id']?.toString();
                      if (id != null && id.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ViewSellerProfileScreen(sellerId: id),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: _secondary),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View public profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A7C2C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Listings count badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_listingsCount',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2D5016),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Listings',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _secondary,
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipOval(
        child: _profile?['shopImage'] != null &&
                _profile!['shopImage'].toString().isNotEmpty
            ? Image.network(_profile!['shopImage'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarIcon())
            : _avatarIcon(),
      ),
    );
  }

  Widget _avatarIcon() =>
      const Icon(Icons.store_rounded, size: 32, color: Colors.white);

  // ─────────────────────────────────────────
  // QUICK ACTIONS — Saved Items
  // ─────────────────────────────────────────
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SavedItemsScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            // Use main screen's gradient style
            gradient: const LinearGradient(
              colors: [Color(0xFF4A7C2C), Color(0xFF2D5016)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF2D5016).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bookmark_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saved Items',
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(height: 1),
                  Text('View all bookmarked listings',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white60),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SELLING SECTION
  // ─────────────────────────────────────────
  Widget _buildSellingSection() {
    return _SectionCard(
      title: 'Selling',
      children: [
        _MenuItem(
          icon: Icons.sell_rounded,
          iconBg: const Color(0xFFF1F5EF),
          iconColor: _secondary,
          title: 'Your listings',
          subtitle: '$_listingsCount active items',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const YourListingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // ACCOUNT SECTION
  // ─────────────────────────────────────────
  Widget _buildAccountSection() {
    final location = _profile?['address'] ?? 'Lahore, Pakistan';

    return _SectionCard(
      title: 'Account',
      children: [
        _InfoRow(
          icon: Icons.verified_rounded,
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF22C55E),
          title: 'Marketplace access',
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A)),
            ),
          ),
        ),
        const _RowDivider(),
        _InfoRow(
          icon: Icons.location_on_outlined,
          iconBg: const Color(0xFFF1F5EF),
          iconColor: _secondary,
          title: 'Location',
          subtitle: location,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  Widget _animatedCard(int index, Widget child) {
    return FadeTransition(
      opacity: _cardFades[index],
      child: SlideTransition(position: _cardSlides[index], child: child),
    );
  }

  // ─────────────────────────────────────────
  // LOADING STATE — matches main screen's simple indicator
  // ─────────────────────────────────────────
  Widget _buildLoadingState() {
    return const SafeArea(
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF4A7C2C)),
      ),
    );
  }
}

// ─────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  static const Color _border = Color(0xFFE0EED4);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0EED4)),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Tappable menu row with chevron
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D5016))),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5EF),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Non-tappable info row
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D5016))),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: Color(0xFFE0EED4)),
    );
  }
}