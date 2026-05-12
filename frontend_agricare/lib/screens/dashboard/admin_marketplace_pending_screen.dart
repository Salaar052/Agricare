// lib/screens/admin/admin_marketplace_pending_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/api_config.dart';
import '../../services/marketplace_service.dart';
import 'admin_marketplace_listing_detail_screen.dart';

class AdminMarketplacePendingScreen extends StatefulWidget {
  const AdminMarketplacePendingScreen({super.key});

  @override
  State<AdminMarketplacePendingScreen> createState() =>
      _AdminMarketplacePendingScreenState();
}

class _AdminMarketplacePendingScreenState
    extends State<AdminMarketplacePendingScreen>
    with TickerProviderStateMixin {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _dark    = Color(0xFF1A2F0E);
  static const _mid     = Color(0xFF4A7C2C);
  static const _light   = Color(0xFF8FAF7A);
  static const _bg      = Color(0xFFF3F8EF);
  static const _card    = Colors.white;
  static const _border  = Color(0xFFD4E8C8);
  static const _surface = Color(0xFFEAF4E5);
  static const _sub     = Color(0xFF7A8F6E);

  // ── State ─────────────────────────────────────────────────────────────────
  late final MarketplaceService _svc;
  bool _loading = true;
  List<dynamic> _pending = [];
  List<dynamic> _all     = [];

  // ── Filter for "All listings" tab ─────────────────────────────────────────
  String _filter = 'all'; // all | pending | approved | rejected

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _staggerCtrl;
  late Animation<double>   _fadeAnim;
  late List<Animation<double>>  _itemFades;
  late List<Animation<Offset>>  _itemSlides;

  @override
  void initState() {
    super.initState();
    _svc = MarketplaceService(baseUrl: ApiConfig.apiV1Base);

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    // pre-allocate for up to 30 visible items
    _itemFades = List.generate(30, (i) {
      final s = (i * 0.04).clamp(0.0, 0.88);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, (s + 0.25).clamp(0, 1), curve: Curves.easeOut)));
    });
    _itemSlides = List.generate(30, (i) {
      final s = (i * 0.04).clamp(0.0, 0.88);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerCtrl,
              curve: Interval(s, (s + 0.25).clamp(0, 1),
                  curve: Curves.easeOutQuart)));
    });

    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.adminGetPendingListings(page: 1, limit: 100),
        _svc.adminGetAllListings(page: 1, limit: 100, status: 'all'),
      ]);
      if (!mounted) return;
      setState(() {
        _pending = results[0]['items'] as List<dynamic>? ?? [];
        _all     = results[1]['items'] as List<dynamic>? ?? [];
        _loading = false;
      });
      _staggerCtrl.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() { _pending = []; _all = []; _loading = false; });
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _posterName(Map<String, dynamic> item) {
    final user = item['userId'];
    if (user is Map) {
      final name = user['username']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
      final email = user['email']?.toString().trim();
      if (email != null && email.isNotEmpty) return email;
    }
    return 'Unknown';
  }

  static String _shopName(Map<String, dynamic> item) {
    final s = item['sellerId'];
    if (s is Map) {
      final n = s['shopName']?.toString().trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return '';
  }

  List<dynamic> get _filteredAll {
    if (_filter == 'all') return _all;
    return _all
        .where((i) => (i as Map)['status']?.toString() == _filter)
        .toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: _load,
          color: _mid,
          backgroundColor: _card,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              _buildAppBar(),
              if (_loading)
                SliverFillRemaining(child: _buildLoader())
              else ...[
                // ── Stats strip ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                    child: _buildStatsStrip(),
                  ),
                ),

                // ── Pending section ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
                    child: _sectionLabel(
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                      title: 'Awaiting Approval',
                      badge: _pending.length,
                    ),
                  ),
                ),
                if (_pending.isEmpty)
                  SliverToBoxAdapter(
                      child: _emptyState(
                    icon: Icons.check_circle_outline_rounded,
                    msg: 'No pending requests',
                    sub: 'All listings have been reviewed.',
                    color: const Color(0xFF16A34A),
                  ))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _animItem(
                          i,
                          _listingCard(
                            _pending[i] as Map<String, dynamic>,
                            section: _Section.pending,
                          ),
                        ),
                        childCount: _pending.length,
                      ),
                    ),
                  ),

                // ── All listings section ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
                    child: _sectionLabel(
                      icon: Icons.storefront_rounded,
                      iconColor: _mid,
                      iconBg: _surface,
                      title: 'All Listings',
                      badge: _all.length,
                    ),
                  ),
                ),

                // Filter bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                    child: _buildFilterBar(),
                  ),
                ),

                if (_filteredAll.isEmpty)
                  SliverToBoxAdapter(
                      child: _emptyState(
                    icon: Icons.inventory_2_outlined,
                    msg: 'No listings found',
                    sub: 'Try a different filter.',
                    color: _light,
                  ))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          // offset index so stagger continues after pending
                          final idx = (_pending.length + i)
                              .clamp(0, _itemFades.length - 1);
                          return _animItem(
                            idx,
                            _listingCard(
                              _filteredAll[i] as Map<String, dynamic>,
                              section: _Section.all,
                            ),
                          );
                        },
                        childCount: _filteredAll.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _dark,
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
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: Colors.white),
          ),
        ),
      ),
      title: const Text(
        'Marketplace Admin',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: _load,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats strip ───────────────────────────────────────────────────────────
  Widget _buildStatsStrip() {
    final pendingCount  = _pending.length;
    final approvedCount = _all
        .where((i) => (i as Map)['status'] == 'approved')
        .length;
    final rejectedCount = _all
        .where((i) => (i as Map)['status'] == 'rejected')
        .length;

    final stats = [
      _Stat('Pending',  '$pendingCount',  const Color(0xFFFEF3C7),
          const Color(0xFFD97706), Icons.schedule_rounded),
      _Stat('Approved', '$approvedCount', const Color(0xFFDCFCE7),
          const Color(0xFF16A34A), Icons.check_circle_rounded),
      _Stat('Rejected', '$rejectedCount', const Color(0xFFFEE2E2),
          const Color(0xFFDC2626), Icons.cancel_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final s = e.value;
          final isLast = e.key == stats.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: s.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s.icon, size: 17, color: s.fg),
                      ),
                      const SizedBox(height: 7),
                      Text(s.value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _dark, height: 1,
                          )),
                      const SizedBox(height: 2),
                      Text(s.label,
                          style: const TextStyle(
                            fontSize: 11, color: _sub,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(width: 1, height: 40, color: _border),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required int badge,
  }) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: _dark, letterSpacing: -0.2,
            )),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$badge',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: iconColor,
              )),
        ),
      ],
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final options = [
      ('all', 'All'),
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: options.map((o) {
          final selected = _filter == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? _card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  o.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected ? _dark : _sub,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Listing card ──────────────────────────────────────────────────────────
  Widget _listingCard(Map<String, dynamic> item,
      {required _Section section}) {
    final id       = item['_id']?.toString() ?? '';
    final title    = item['title']?.toString() ?? 'Untitled';
    final price    = item['price']?.toString() ?? '';
    final poster   = _posterName(item);
    final shop     = _shopName(item);
    final category = item['category']?.toString() ?? '';
    final status   = item['status']?.toString() ?? '';

    // image
    final imgs = item['images'];
    final firstImg = (imgs is List && imgs.isNotEmpty)
        ? imgs.first?.toString()
        : null;

    return GestureDetector(
      onTap: id.isEmpty
          ? null
          : () async {
              await Get.to(
                () => AdminMarketplaceListingDetailScreen(
                    productId: id),
                transition: Transition.rightToLeftWithFade,
                duration: const Duration(milliseconds: 300),
              );
              _staggerCtrl.reset();
              await _load();
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Thumbnail or icon
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: firstImg != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          firstImg,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_rounded,
                              color: _light, size: 24),
                        ),
                      )
                    : const Icon(Icons.inventory_2_rounded,
                        color: _light, size: 24),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _dark,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusPill(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (price.isNotEmpty)
                      Text(
                        'PKR $price',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _mid,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 12, color: _sub),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            poster,
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: _sub,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (shop.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3, height: 3,
                            decoration: const BoxDecoration(
                              color: _light, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.storefront_rounded,
                              size: 12, color: _sub),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              shop,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _sub,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _mid,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: _light),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A);
        label = 'Approved'; break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626);
        label = 'Rejected'; break;
      default:
        bg = const Color(0xFFFEF3C7); fg = const Color(0xFFD97706);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String msg,
    required String sub,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5, color: _sub, height: 1.4)),
          ],
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _surface, borderRadius: BorderRadius.circular(14)),
            child: const Padding(
              padding: EdgeInsets.all(13),
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: _mid),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Loading listings…',
              style: TextStyle(
                  fontSize: 13, color: _sub, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Stagger helper ────────────────────────────────────────────────────────
  Widget _animItem(int i, Widget child) {
    final idx = i.clamp(0, _itemFades.length - 1);
    return FadeTransition(
      opacity: _itemFades[idx],
      child: SlideTransition(position: _itemSlides[idx], child: child),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────
enum _Section { pending, all }

class _Stat {
  final String label, value;
  final Color bg, fg;
  final IconData icon;
  const _Stat(this.label, this.value, this.bg, this.fg, this.icon);
}