// lib/screens/marketplace/view_seller_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/marketplace_service.dart';
import '../../api/api_config.dart';

class ViewSellerProfileScreen extends StatefulWidget {
  final String sellerId;

  const ViewSellerProfileScreen({super.key, required this.sellerId});

  @override
  State<ViewSellerProfileScreen> createState() =>
      _ViewSellerProfileScreenState();
}

class _ViewSellerProfileScreenState extends State<ViewSellerProfileScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;

  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<dynamic> _listings = [];

  // ── Animation controllers ──
  late AnimationController _enterController;
  late AnimationController _staggerController;

  late Animation<double> _fadeBg;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  // ── Design tokens — matched to MarketplaceMainScreen ──
  static const Color _primary   = Color(0xFF2D5016);
  static const Color _secondary = Color(0xFF4A7C2C);
  static const Color _light     = Color(0xFF7A9B6A);
  static const Color _bg        = Color(0xFFF8FBF8);
  static const Color _border    = Color(0xFFE0EED4);
  static const Color _surface   = Color(0xFFF1F5EF);

  static const Map<String, Color> _catColors = {
    'Seeds':       Color(0xFF4A7C2C),
    'Fertilizers': Color(0xFF2D5016),
    'Pesticides':  Color(0xFF7A9B6A),
    'Machinery':   Color(0xFF5B8A3C),
    'Livestock':   Color(0xFF3D6B1E),
  };

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);
    _loadSellerProfile();

    _enterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeBg = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _enterController.forward();

    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _cardFades = List.generate(6, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _staggerController,
          curve: Interval(s, (s + 0.28).clamp(0.0, 1.0), curve: Curves.easeOut)));
    });
    _cardSlides = List.generate(6, (i) {
      final s = (i * 0.12).clamp(0.0, 0.88);
      return Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(s, (s + 0.28).clamp(0.0, 1.0),
                  curve: Curves.easeOutQuart)));
    });
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _staggerController.forward(); });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerProfile() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await _marketplaceService.getPublicSellerProfile(widget.sellerId);
      setState(() {
        _profile  = response['profile'];
        _stats    = response['stats'];
        _listings = response['listings'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load seller profile');
    }
  }

  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeBg,
        child: _isLoading ? _buildLoadingState() : _buildBody(),
      ),
    );
  }

  // ──────────────────────────────────────────
  // BODY
  // ──────────────────────────────────────────
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
                    _animatedCard(0, _buildStatsRow()),
                    const SizedBox(height: 12),
                    if ((_profile?['shopDescription'] ?? '').toString().isNotEmpty) ...[
                      _animatedCard(1, _buildAboutSection()),
                      const SizedBox(height: 12),
                    ],
                    _animatedCard(2, _buildDetailsSection()),
                    const SizedBox(height: 12),
                    if ((_stats?['categoryBreakdown'] as List?)?.isNotEmpty == true) ...[
                      _animatedCard(3, _buildCategoriesSection()),
                      const SizedBox(height: 12),
                    ],
                    if (_listings.isNotEmpty) ...[
                      _animatedCard(4, _buildListingsSection()),
                      const SizedBox(height: 12),
                    ],
                    _buildMemberSince(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // TOP BAR — mirrors MarketplaceMainScreen header exactly
  // ──────────────────────────────────────────
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
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seller Profile',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5016)),
                ),
                Text(
                  'View store & listings',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded,
                  color: Color(0xFF2D5016)),
              onPressed: _showOptionsSheet,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // PROFILE HEADER CARD
  // ──────────────────────────────────────────
  Widget _buildProfileHeader() {
    final totalListings = _stats?['totalListings'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(18),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with active dot
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A7C2C), Color(0xFF2D5016)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                          errorBuilder: (_, __, ___) => _avatarPlaceholder())
                      : _avatarPlaceholder(),
                ),
              ),
              if (_profile?['isActive'] == true)
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF22C55E),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Name + location + verified badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?['shopName'] ?? 'Seller',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((_profile?['address'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _profile!['address'],
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                // Verified badge — gradient matches main screen category pills
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A7C2C), Color(0xFF2D5016)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 10, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Verified Seller',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Listings count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalListings',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D5016),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
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
    );
  }

  Widget _avatarPlaceholder() => Container(
        color: _secondary,
        child: const Icon(Icons.store_rounded, size: 32, color: Colors.white),
      );

  // ──────────────────────────────────────────
  // STATS ROW
  // ──────────────────────────────────────────
  Widget _buildStatsRow() {
    final sold   = _stats?['soldCount']      ?? 0;
    final active = _stats?['activeListings'] ?? 0;
    final since  = _profile?['memberSince']  ?? '—';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildStatCell(
              value: '$sold',
              label: 'Items sold',
              icon: Icons.sell_rounded,
              iconColor: _secondary),
          _buildStatDivider(),
          _buildStatCell(
              value: '$active',
              label: 'Active now',
              icon: Icons.storefront_rounded,
              iconColor: _primary),
          _buildStatDivider(),
          _buildStatCell(
              value: '$since',
              label: 'Member since',
              icon: Icons.calendar_today_rounded,
              iconColor: _light),
        ],
      ),
    );
  }

  Widget _buildStatCell({
    required String value,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2D5016),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // ──────────────────────────────────────────
  // ABOUT SECTION
  // ──────────────────────────────────────────
  Widget _buildAboutSection() {
    final desc = _profile?['shopDescription'] ?? '';
    final bio  = _profile?['sellerBio'] ?? '';

    return _buildSection(
      icon: Icons.info_outline_rounded,
      title: 'About the shop',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (desc.toString().isNotEmpty)
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF4A7C2C),
                  height: 1.65,
                ),
              ),
            if (bio.toString().isNotEmpty && desc.toString().isNotEmpty)
              const SizedBox(height: 10),
            if (bio.toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bio,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D5016),
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
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

  // ──────────────────────────────────────────
  // DETAILS SECTION
  // ──────────────────────────────────────────
  Widget _buildDetailsSection() {
    final address = _profile?['address'] ?? '';
    final email   = _profile?['contactInfo']?['email'] ?? '';
    final name    = _profile?['contactInfo']?['name'] ?? '';

    return _buildSection(
      icon: Icons.manage_accounts_rounded,
      title: 'Seller details',
      child: Column(
        children: [
          if (name.toString().isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.person_rounded,
              iconBg: _surface,
              iconColor: _secondary,
              label: 'Seller name',
              value: name,
            ),
            _buildSectionDivider(),
          ],
          if (address.toString().isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.location_on_rounded,
              iconBg: _surface,
              iconColor: _secondary,
              label: 'Location',
              value: address,
            ),
            _buildSectionDivider(),
          ],
          if (email.toString().isNotEmpty) ...[
            _buildDetailRow(
              icon: Icons.email_rounded,
              iconBg: _surface,
              iconColor: _secondary,
              label: 'Contact email',
              value: email,
            ),
            _buildSectionDivider(),
          ],
          _buildDetailRow(
            icon: Icons.verified_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF22C55E),
            label: 'Marketplace status',
            value: 'Verified seller',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D5016)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // CATEGORIES SECTION
  // ──────────────────────────────────────────
  Widget _buildCategoriesSection() {
    final cats = (_stats?['categoryBreakdown'] as List?) ?? [];

    return _buildSection(
      icon: Icons.category_rounded,
      title: 'Categories',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cats.map((cat) {
            final name  = cat['_id']?.toString() ?? '';
            final count = cat['count'] ?? 0;
            final color = _catColors[name] ?? _secondary;
            // Re-use the same animated container style as main screen category pills
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$name ($count)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // LISTINGS SECTION — matches main screen product card style
  // ──────────────────────────────────────────
  Widget _buildListingsSection() {
    final preview = _listings.take(6).toList();

    return _buildSection(
      icon: Icons.grid_view_rounded,
      title: 'Active listings  (${_stats?['activeListings'] ?? 0})',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: preview.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.72, // same as main screen
              ),
              itemBuilder: (context, i) =>
                  _buildProductCard(preview[i]),
            ),
          ),
          if (_listings.length > 6)
            GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See all ${_listings.length} listings',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D5016)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: Color(0xFF2D5016)),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Product card — identical structure to MarketplaceMainScreen._buildProductCard
  Widget _buildProductCard(Map<String, dynamic> product) {
    final images   = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final isUsed   = product['condition'] == 'used';

    return GestureDetector(
      onTap: () {
        // Get.to(() => ProductDetailsScreen(productId: product['_id']));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0EED4).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _listingPlaceholder(product['category']))
                    : _listingPlaceholder(product['category']),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Text(
                          'Rs ${product['price']}',
                          style: const TextStyle(
                              color: Color(0xFF2D5016),
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isUsed
                                ? const Color(0xFFFEF9C3)
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isUsed ? 'Used' : 'New',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isUsed
                                  ? const Color(0xFF854F0B)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product['location']?['address'] ?? 'Pakistan',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listingPlaceholder(String? category) {
    const icons = {
      'Seeds':       Icons.grass_rounded,
      'Fertilizers': Icons.science_rounded,
      'Pesticides':  Icons.bug_report_rounded,
      'Machinery':   Icons.agriculture_rounded,
      'Livestock':   Icons.pets_rounded,
    };
    return Container(
      color: _surface,
      child: Center(
        child: Icon(
          icons[category] ?? Icons.storefront_rounded,
          size: 34,
          color: _secondary.withOpacity(0.5),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // MEMBER SINCE FOOTER
  // ──────────────────────────────────────────
  Widget _buildMemberSince() {
    final since = _profile?['memberSince'];
    if (since == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
          const SizedBox(width: 5),
          Text(
            'Member since $since',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // OPTIONS BOTTOM SHEET
  // ──────────────────────────────────────────
  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            _buildSheetOption(
              icon: Icons.share_rounded,
              label: 'Share profile',
              onTap: () => Navigator.of(context).pop(),
            ),
            Divider(height: 1, color: _border),
            _buildSheetOption(
              icon: Icons.flag_rounded,
              label: 'Report seller',
              color: const Color(0xFFDC2626),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? _primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: c.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: c),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // SECTION WRAPPER
  // ──────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _cardDecoration(),
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
          child,
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 72),
      child: Divider(height: 1, color: Color(0xFFE0EED4)),
    );
  }

  Widget _animatedCard(int index, Widget child) {
    return FadeTransition(
      opacity: _cardFades[index],
      child: SlideTransition(position: _cardSlides[index], child: child),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3)),
      ],
    );
  }

  // ──────────────────────────────────────────
  // LOADING STATE — matches main screen's simple indicator
  // ──────────────────────────────────────────
  Widget _buildLoadingState() {
    return const SafeArea(
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF4A7C2C)),
      ),
    );
  }
}