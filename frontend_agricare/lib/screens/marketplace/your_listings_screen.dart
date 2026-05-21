// lib/screens/marketplace/your_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/marketplace_service.dart';
import 'create_listing_screen.dart';
import 'view_listing_screen.dart';
import '../../api/api_config.dart';

class YourListingsScreen extends StatefulWidget {
  const YourListingsScreen({super.key});

  @override
  State<YourListingsScreen> createState() => _YourListingsScreenState();
}

class _YourListingsScreenState extends State<YourListingsScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;

  bool _isLoading = true;
  List<dynamic> _listings = [];
  String _searchQuery = '';

  // ── Palette (uniform with marketplace screens) ──
  static const _dark    = Color(0xFF2D5016);
  static const _mid     = Color(0xFF4A7C2C);
  static const _light   = Color(0xFF7A9B6A);
  static const _bg      = Color(0xFFF6FAF4);
  static const _border  = Color(0xFFE3EFD9);
  static const _surface = Color(0xFFEAF3E3);

  // ── Animation controllers ──
  late AnimationController _enterController;
  late AnimationController _staggerController;
  late AnimationController _searchPulseController;
  late AnimationController _shimmerController;
  late AnimationController _fabController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _searchScale;
  late Animation<double> _shimmerAnim;
  late Animation<double> _fabScale;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);
    _loadListings();

    // 1. Screen enter
    _enterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _fadeAnim =
        CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _enterController, curve: Curves.easeOutQuart));
    _enterController.forward();

    // 2. List items stagger (up to 12)
    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _itemFades = List.generate(12, (i) {
      final s = (i * 0.07).clamp(0.0, 0.9);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _staggerController,
          curve: Interval(s, (s + 0.25).clamp(0.0, 1.0),
              curve: Curves.easeOut)));
    });
    _itemSlides = List.generate(12, (i) {
      final s = (i * 0.07).clamp(0.0, 0.9);
      return Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(s, (s + 0.25).clamp(0.0, 1.0),
                  curve: Curves.easeOutQuart)));
    });
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _staggerController.forward(); });

    // 3. Search bar breathe
    _searchPulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _searchScale = Tween<double>(begin: 1.0, end: 1.005).animate(
        CurvedAnimation(
            parent: _searchPulseController, curve: Curves.easeInOut));

    // 4. Shimmer
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -2.0, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));

    // 5. FAB spring
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fabController, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _fabController.forward(); });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _staggerController.dispose();
    _searchPulseController.dispose();
    _shimmerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    try {
      final listings = await _marketplaceService.getMyListings();
      setState(() {
        _listings = listings;
        _isLoading = false;
      });
      // Re-run stagger on fresh data
      _staggerController.reset();
      Future.delayed(const Duration(milliseconds: 100),
          () { if (mounted) _staggerController.forward(); });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load listings');
    }
  }

  List<dynamic> get _filteredListings {
    if (_searchQuery.isEmpty) return _listings;
    return _listings.where((listing) {
      final title = listing['title']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // ── Status helper ──
  _StatusInfo _getStatus(Map<String, dynamic> listing) {
    final status = listing['status'] ?? 'pending';
    final isAvailable = listing['isAvailable'] ?? false;
    final isSold = listing['isSold'] ?? false;

    if (status == 'approved') {
      if (isSold) return _StatusInfo('Sold', const Color(0xFF7A9B6A), Icons.check_circle_rounded);
      if (!isAvailable) return _StatusInfo('Out of stock', const Color(0xFFEF4444), Icons.remove_circle_rounded);
      return _StatusInfo('Available', const Color(0xFF22C55E), Icons.verified_rounded);
    }
    if (status == 'rejected') return _StatusInfo('Rejected', const Color(0xFFEF4444), Icons.cancel_rounded);
    return _StatusInfo('Pending', const Color(0xFFF59E0B), Icons.schedule_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredListings.isEmpty
                        ? _buildEmptyState()
                        : _buildListings(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreateListingScreen(),
              ),
            );
            if (result == true) _loadListings();
          },
          backgroundColor: _dark,
          elevation: 6,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          label: const Text(
            'New Listing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Header
  // ──────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 18,
        right: 18,
        bottom: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bg,
                border: Border.all(color: _border, width: 1.2),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: _dark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Listings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _dark,
                    letterSpacing: -0.4,
                    height: 1.1,
                  ),
                ),
                AnimatedBuilder(
                  animation: _staggerController,
                  builder: (_, __) => Text(
                    '${_listings.length} item${_listings.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _light,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Search Bar
  // ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Column(
        children: [
          const Divider(color: Color(0xFFE8F0E4), height: 1),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _searchPulseController,
            builder: (context, child) => Transform.scale(
              scale: _searchScale.value,
              child: child,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _dark.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E3A0F),
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search your listings…',
                  hintStyle: TextStyle(
                    color: _mid.withOpacity(0.38),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: _mid, size: 20),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _border, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: _border, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _mid, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Listings List
  // ──────────────────────────────────────────
  Widget _buildListings() {
    return RefreshIndicator(
      onRefresh: _loadListings,
      color: _mid,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
        itemCount: _filteredListings.length,
        itemBuilder: (context, index) {
          final i = index.clamp(0, 11);
          return FadeTransition(
            opacity: _itemFades[i],
            child: SlideTransition(
              position: _itemSlides[i],
              child: _buildListingCard(_filteredListings[index], index),
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────
  // Listing Card
  // ──────────────────────────────────────────
  Widget _buildListingCard(Map<String, dynamic> listing, int index) {
    final images = listing['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final info = _getStatus(listing);

    return GestureDetector(
      onTap: () => _showListingOptions(listing),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: _dark.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          loadingBuilder: (ctx, child, prog) =>
                              prog == null ? child : _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),

              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _dark,
                        letterSpacing: 0.1,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Rs ${listing['price']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _dark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: info.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: info.color.withOpacity(0.25),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(info.icon,
                                  size: 12, color: info.color),
                              const SizedBox(width: 4),
                              Text(
                                info.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: info.color,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // More button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert_rounded,
                    size: 16, color: _light),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _surface,
      child: Center(
        child: Icon(Icons.image_rounded,
            size: 32, color: _mid.withOpacity(0.25)),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Bottom Sheet Options
  // ──────────────────────────────────────────
  void _showListingOptions(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title row
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_dark, _mid],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        listing['title'] ?? 'Listing',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _dark,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 6),

              _sheetItem(
                icon: Icons.visibility_rounded,
                iconBg: _surface,
                iconColor: _mid,
                label: 'View listing',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ViewListingScreen(listing: listing),
                    ),
                  );
                },
              ),

              if (listing['status'] != 'approved' ||
                  !(listing['isSold'] ?? false))
                _sheetItem(
                  icon: Icons.edit_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Edit listing',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateListingScreen(
                          initialListing: listing,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadListings();
                    }
                  },
                ),

              if (listing['status'] == 'approved' &&
                  !(listing['isSold'] ?? false))
                _sheetItem(
                  icon: listing['isAvailable']
                      ? Icons.remove_circle_rounded
                      : Icons.check_circle_rounded,
                  iconBg: listing['isAvailable']
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFDCFCE7),
                  iconColor: listing['isAvailable']
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF22C55E),
                  label: listing['isAvailable']
                      ? 'Mark as out of stock'
                      : 'Mark as in stock',
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _marketplaceService.updateMyListing(
                        itemId: listing['_id'],
                        isAvailable: !(listing['isAvailable'] ?? false),
                      );
                      _loadListings();
                    } catch (e) {
                      _marketplaceService
                          .showError('Failed to update listing');
                    }
                  },
                ),

              _sheetItem(
                icon: Icons.delete_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
                label: 'Delete listing',
                labelColor: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(listing);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: _mid.withOpacity(0.07),
      highlightColor: _mid.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: labelColor ?? _dark,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Confirm Delete Dialog
  // ──────────────────────────────────────────
  void _confirmDelete(Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete listing?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${listing['title']}"? This cannot be undone.',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _light,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _mid,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _marketplaceService
                    .deleteMyListing(listing['_id']);
                _loadListings();
              } catch (e) {
                _marketplaceService
                    .showError('Failed to delete listing');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Empty State
  // ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mid.withOpacity(0.08),
              ),
              child: const Icon(Icons.storefront_rounded,
                  size: 42, color: _mid),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty ? 'No listings yet' : 'Nothing found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _dark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isEmpty
                  ? 'Tap the button below\nto create your first listing.'
                  : 'Try a different search term.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _light,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Loading skeleton
  // ──────────────────────────────────────────
  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) => ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1),
          ),
          child: Row(
            children: [
              _shimmerBox(82, 82, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(14, double.infinity),
                    const SizedBox(height: 8),
                    _shimmerBox(14, 120),
                    const SizedBox(height: 8),
                    _shimmerBox(22, 80, radius: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 8}) {
    return Stack(
      children: [
        Container(
          height: height,
          width: width == double.infinity ? null : width,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Align(
            alignment: Alignment(_shimmerAnim.value, 0),
            child: Container(
              height: height,
              width: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.55),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status data class ──
class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusInfo(this.label, this.color, this.icon);
}