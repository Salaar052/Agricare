// lib/screens/admin/admin_marketplace_listing_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/api_config.dart';
import '../../services/marketplace_service.dart';

class AdminMarketplaceListingDetailScreen extends StatefulWidget {
  const AdminMarketplaceListingDetailScreen(
      {super.key, required this.productId});
  final String productId;

  @override
  State<AdminMarketplaceListingDetailScreen> createState() =>
      _State();
}

class _State extends State<AdminMarketplaceListingDetailScreen>
    with TickerProviderStateMixin {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const _dark    = Color(0xFF1A2F0E);
  static const _mid     = Color(0xFF4A7C2C);
  static const _light   = Color(0xFF8FAF7A);
  static const _bg      = Color(0xFFF3F8EF);
  static const _cardColor = Colors.white;
  static const _border  = Color(0xFFD4E8C8);
  static const _surface = Color(0xFFEAF4E5);
  static const _sub     = Color(0xFF7A8F6E);

  // ── Service / state ───────────────────────────────────────────────────────
  late final MarketplaceService _svc;
  bool _loading = true;
  bool _acting  = false;
  Map<String, dynamic> _item = {};

  // ── Image page ────────────────────────────────────────────────────────────
  int _imgPage = 0;
  final _pageCtrl = PageController();

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late AnimationController _staggerCtrl;
  late Animation<double>   _fadeAnim;
  late List<Animation<double>>  _secFades;
  late List<Animation<Offset>>  _secSlides;

  @override
  void initState() {
    super.initState();
    _svc = MarketplaceService(baseUrl: ApiConfig.apiV1Base);

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _secFades = List.generate(6, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(s, (s + 0.3).clamp(0, 1), curve: Curves.easeOut)));
    });
    _secSlides = List.generate(6, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerCtrl,
              curve: Interval(s, (s + 0.3).clamp(0, 1),
                  curve: Curves.easeOutQuart)));
    });

    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _staggerCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final item = await _svc.getProductDetails(widget.productId);
      if (mounted) {
        setState(() { _item = item; _loading = false; });
        _staggerCtrl.forward(from: 0);
      }
    } catch (e) {
      _svc.showError(e.toString().replaceAll('Exception: ', ''));
      if (mounted) setState(() { _item = {}; _loading = false; });
    }
  }

  Future<void> _approve() async {
    setState(() => _acting = true);
    try {
      await _svc.adminApproveListing(widget.productId);
      if (mounted) {
        _staggerCtrl.reset();
        await _load();
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    final ctrl = TextEditingController();
    final reason = await Get.dialog<String>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: _cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.cancel_rounded,
                        color: Color(0xFFDC2626), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reject Listing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Rejection reason (optional)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _sub,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 3,
                style: const TextStyle(
                    fontSize: 14, color: _dark, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Visible to the seller…',
                  hintStyle: TextStyle(
                      color: _light.withOpacity(0.8), fontSize: 13.5),
                  filled: true,
                  fillColor: _bg,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _mid, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _border),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: const Center(
                          child: Text('Cancel',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _dark,
                                  fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(result: ctrl.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Reject',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (reason == null) return;

    setState(() => _acting = true);
    try {
      await _svc.adminRejectListing(widget.productId,
          rejectionReason: reason.isEmpty ? null : reason);
      if (mounted) {
        _staggerCtrl.reset();
        await _load();
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<String> get _images {
    final raw = _item['images'];
    if (raw is! List) return [];
    return raw.whereType<String>().where((s) => s.isNotEmpty).toList();
  }

  Map<String, dynamic>? get _seller {
    final s = _item['sellerId'];
    return s is Map ? Map<String, dynamic>.from(s) : null;
  }

  Map<String, dynamic>? get _farmer {
    final u = _item['userId'];
    return u is Map ? Map<String, dynamic>.from(u) : null;
  }

  String get _status => _item['status']?.toString() ?? '';
  bool   get _isPending  => _status == 'pending';
  bool   get _isApproved => _status == 'approved';
  bool   get _isRejected => _status == 'rejected';

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _loading
            ? _buildSkeleton()
            : _item.isEmpty
                ? _buildError()
                : _buildBody(),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(String title) {
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
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: Colors.white),
          ),
        ),
      ),
      title: Text(
        title.isEmpty ? 'Listing Detail' : title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ── Loading skeleton ──────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(''),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _shimBox(220, double.infinity, r: 20),
                const SizedBox(height: 16),
                _shimBox(140, double.infinity, r: 18),
                const SizedBox(height: 12),
                _shimBox(120, double.infinity, r: 18),
                const SizedBox(height: 12),
                _shimBox(100, double.infinity, r: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimBox(double h, double w, {double r = 10}) => Container(
        height: h,
        width: w == double.infinity ? null : w,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(''),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: _surface, shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded,
                      size: 36, color: _mid),
                ),
                const SizedBox(height: 16),
                const Text('Could not load listing',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _dark)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                        color: _mid,
                        borderRadius: BorderRadius.circular(30)),
                    child: const Text('Retry',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Main body ─────────────────────────────────────────────────────────────
  Widget _buildBody() {
    final title     = _item['title']?.toString() ?? '';
    final price     = _item['price']?.toString() ?? '';
    final category  = _item['category']?.toString() ?? '';
    final subcat    = _item['subcategory']?.toString() ?? '';
    final desc      = _item['description']?.toString() ?? '';
    final condition = _item['condition']?.toString() ?? '';
    final rejection = _item['rejectionReason']?.toString();
    final imgs      = _images;
    final seller    = _seller;
    final farmer    = _farmer;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(title),
        SliverToBoxAdapter(
          child: Column(
            children: [
              // ── Image carousel ──────────────────────────────────────────
              if (imgs.isNotEmpty) ...[
                _anim(0, _buildImageCarousel(imgs)),
                const SizedBox(height: 18),
              ] else ...[
                const SizedBox(height: 18),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title + status row ──────────────────────────────
                    _anim(0, _buildTitleRow(title, price)),
                    const SizedBox(height: 14),

                    // ── Status badge + meta card ────────────────────────
                    _anim(1, _buildMetaCard(category, subcat, condition)),
                    const SizedBox(height: 14),

                    // ── Farmer info ─────────────────────────────────────
                    if (farmer != null) ...[
                      _anim(2, _buildInfoCard(
                        icon: Icons.person_rounded,
                        iconColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFE0F2FE),
                        title: 'Seller Account',
                        rows: [
                          _InfoRow('Username',
                              farmer['username']?.toString() ?? '—'),
                          _InfoRow('Email',
                              farmer['email']?.toString() ?? '—'),
                        ],
                      )),
                      const SizedBox(height: 14),
                    ],

                    // ── Shop profile ────────────────────────────────────
                    if (seller != null) ...[
                      _anim(3, _buildInfoCard(
                        icon: Icons.storefront_rounded,
                        iconColor: const Color(0xFFD97706),
                        iconBg: const Color(0xFFFEF3C7),
                        title: 'Shop Profile',
                        rows: [
                          _InfoRow('Shop name',
                              seller['shopName']?.toString() ?? '—'),
                          if ((seller['address']?.toString() ?? '').isNotEmpty)
                            _InfoRow('Address',
                                seller['address']!.toString()),
                        ],
                      )),
                      const SizedBox(height: 14),
                    ],

                    // ── Description ─────────────────────────────────────
                    if (desc.isNotEmpty) ...[
                      _anim(4, _buildDescCard(desc)),
                      const SizedBox(height: 14),
                    ],

                    // ── Rejection reason ────────────────────────────────
                    if (_isRejected &&
                        rejection != null &&
                        rejection.isNotEmpty) ...[
                      _anim(4, _buildRejectionBanner(rejection)),
                      const SizedBox(height: 14),
                    ],

                    // ── Action buttons ──────────────────────────────────
                    _anim(5, _buildActions()),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Image carousel ────────────────────────────────────────────────────────
  Widget _buildImageCarousel(List<String> imgs) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: imgs.length,
            onPageChanged: (i) => setState(() => _imgPage = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imgs[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: _surface,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          size: 40, color: _light),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (imgs.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imgs.length, (i) {
              final active = i == _imgPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? _mid : _border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  // ── Title row ─────────────────────────────────────────────────────────────
  Widget _buildTitleRow(String title, String price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              if (price.isNotEmpty)
                Text(
                  'PKR $price',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _mid,
                    letterSpacing: -0.2,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _statusChip(_status),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    IconData icon;
    String label;
    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        icon = Icons.check_circle_rounded;
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        icon = Icons.cancel_rounded;
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        icon = Icons.schedule_rounded;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ],
      ),
    );
  }

  // ── Meta card ─────────────────────────────────────────────────────────────
  Widget _buildMetaCard(String category, String subcat, String condition) {
    return _card(
      child: Column(
        children: [
          _detailRow(Icons.category_rounded, 'Category',
              [category, subcat].where((s) => s.isNotEmpty).join(' / ')),
          if (condition.isNotEmpty) ...[
            _cardDivider(),
            _detailRow(Icons.star_rounded, 'Condition', condition),
          ],
        ],
      ),
    );
  }

  // ── Generic info card ─────────────────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required List<_InfoRow> rows,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 10),
          ...rows.map((r) => _detailRow(null, r.key, r.value)),
        ],
      ),
    );
  }

  // ── Description card ──────────────────────────────────────────────────────
  Widget _buildDescCard(String desc) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.description_rounded,
                    size: 16, color: _mid),
              ),
              const SizedBox(width: 10),
              const Text('Description',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF4A5E3A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Rejection banner ──────────────────────────────────────────────────────
  Widget _buildRejectionBanner(String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cancel_rounded,
                color: Color(0xFFDC2626), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rejection Reason',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF991B1B),
                    )),
                const SizedBox(height: 4),
                Text(reason,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFDC2626),
                      height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────
  Widget _buildActions() {
    if (_isPending) {
      return Row(
        children: [
          Expanded(child: _rejectBtn()),
          const SizedBox(width: 12),
          Expanded(child: _approveBtn()),
        ],
      );
    }

    // Non-pending status message
    Color bg, fg, borderColor;
    IconData icon;
    String msg;
    if (_isApproved) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      borderColor = const Color(0xFFBBF7D0);
      icon = Icons.check_circle_rounded;
      msg = 'This listing is approved and visible in the marketplace.';
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
      borderColor = const Color(0xFFE2E8F0);
      icon = Icons.info_rounded;
      msg = 'This listing is not pending — no action available.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    fontSize: 13, color: fg, height: 1.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _approveBtn() {
    return GestureDetector(
      onTap: _acting ? null : _approve,
      child: AnimatedOpacity(
        opacity: _acting ? 0.6 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: _mid,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _mid.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: _acting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 7),
                      Text('Approve',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _rejectBtn() {
    return GestureDetector(
      onTap: _acting ? null : _reject,
      child: AnimatedOpacity(
        opacity: _acting ? 0.6 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_rounded,
                    color: Color(0xFFDC2626), size: 18),
                SizedBox(width: 7),
                Text('Reject',
                    style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable card shell ───────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _detailRow(IconData? icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: _surface, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: _mid),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: _sub,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: _dark,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _cardDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Divider(height: 12, color: _border),
      );

  // ── Stagger animation helper ──────────────────────────────────────────────
  Widget _anim(int i, Widget child) => FadeTransition(
        opacity: _secFades[i],
        child: SlideTransition(position: _secSlides[i], child: child),
      );
}

// ── Simple data class ─────────────────────────────────────────────────────────
class _InfoRow {
  final String key;
  final String value;
  const _InfoRow(this.key, this.value);
}