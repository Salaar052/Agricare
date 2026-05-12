// lib/screens/marketplace/view_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../api/api_config.dart';
import '../../services/marketplace_service.dart';
import 'create_listing_screen.dart';

class ViewListingScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ViewListingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<ViewListingScreen> createState() => _ViewListingScreenState();
}

class _ViewListingScreenState extends State<ViewListingScreen>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  late final MarketplaceService _marketplaceService;
  late Map<String, dynamic> _listing;

  // ── Palette ──
  static const _dark    = Color(0xFF2D5016);
  static const _mid     = Color(0xFF4A7C2C);
  static const _light   = Color(0xFF7A9B6A);
  static const _bg      = Color(0xFFF6FAF4);
  static const _border  = Color(0xFFE3EFD9);
  static const _surface = Color(0xFFEAF3E3);

  // ── Animations ──
  late AnimationController _enterController;
  late AnimationController _staggerController;

  late Animation<double> _fadeAnim;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();

    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);
    _listing = Map<String, dynamic>.from(widget.listing);

    _enterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _enterController.forward();

    _staggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _cardFades = List.generate(8, (i) {
      final s = (i * 0.1).clamp(0.0, 0.88);
      return Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _staggerController,
          curve: Interval(s, (s + 0.28).clamp(0.0, 1.0),
              curve: Curves.easeOut)));
    });
    _cardSlides = List.generate(8, (i) {
      final s = (i * 0.1).clamp(0.0, 0.88);
      return Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(s, (s + 0.28).clamp(0.0, 1.0),
                  curve: Curves.easeOutQuart)));
    });
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _staggerController.forward(); });
  }

  @override
  void dispose() {
    _enterController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    final i = index.clamp(0, 7);
    return FadeTransition(
      opacity: _cardFades[i],
      child: SlideTransition(position: _cardSlides[i], child: child),
    );
  }

  // ── Status helper ──
  _StatusInfo _getStatus() {
    final status = _listing['status'] ?? 'pending';
    final isAvailable = _listing['isAvailable'] ?? false;
    final isSold = _listing['isSold'] ?? false;
    if (status == 'approved') {
      if (isSold) return _StatusInfo('Sold', _light, Icons.check_circle_rounded);
      if (!isAvailable) return _StatusInfo('Out of Stock', const Color(0xFFEF4444), Icons.remove_circle_rounded);
      return _StatusInfo('Available', const Color(0xFF22C55E), Icons.verified_rounded);
    }
    if (status == 'rejected') return _StatusInfo('Rejected', const Color(0xFFEF4444), Icons.cancel_rounded);
    return _StatusInfo('Pending Approval', const Color(0xFFF59E0B), Icons.schedule_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final images = _listing['images'] as List? ?? [];

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(images),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  _animated(0, _buildStatusBadge()),
                  const SizedBox(height: 10),
                  _animated(1, _buildProductInfoCard()),
                  const SizedBox(height: 10),
                  _animated(2, _buildDescriptionCard()),
                  const SizedBox(height: 10),
                  _animated(3, _buildSellerInfoCard()),
                  const SizedBox(height: 10),
                  _animated(4, _buildLocationCard()),
                  const SizedBox(height: 10),
                  _animated(5, _buildDetailsCard()),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Sliver App Bar
  // ──────────────────────────────────────────
  Widget _buildSliverAppBar(List images) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _dark.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: _dark),
          ),
        ),
      ),
      actions: [
        if (!(_listing['isSold'] ?? false))
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _dark.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18, color: _dark),
                onPressed: _editListing,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _dark.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, size: 18, color: _dark),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: images.isNotEmpty
            ? Stack(
                children: [
                  CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: images.length,
                    itemBuilder: (context, index, realIndex) {
                      return Container(
                        width: double.infinity,
                        color: _surface,
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, prog) {
                            if (prog == null) return child;
                            return Container(
                              color: _surface,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _mid,
                                  strokeWidth: 2,
                                  value: prog.expectedTotalBytes != null
                                      ? prog.cumulativeBytesLoaded /
                                          prog.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: _surface,
                              child: const Center(
                                child: Icon(Icons.image_rounded,
                                    size: 60, color: _light),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: images.length > 1,
                      onPageChanged: (index, reason) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                  ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Image counter pill
                  if (images.length > 1)
                    Positioned(
                      bottom: 18,
                      right: 18,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  // Dot indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          final active = _currentImageIndex == entry.key;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutQuart,
                            width: active ? 18 : 7,
                            height: 7,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              )
            : Container(
                color: _surface,
                child: const Center(
                  child: Icon(Icons.image_rounded,
                      size: 80, color: _light),
                ),
              ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Status Badge
  // ──────────────────────────────────────────
  Widget _buildStatusBadge() {
    final info = _getStatus();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: info.color.withOpacity(0.22), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(info.icon, color: info.color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Listing Status',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _light,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                info.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: info.color,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Product Info Card
  // ──────────────────────────────────────────
  Widget _buildProductInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.category_rounded, size: 12, color: _mid),
                const SizedBox(width: 5),
                Text(
                  _listing['category'] ?? 'Uncategorized',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _mid,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            _listing['title'] ?? 'No title',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _dark,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Rs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _mid,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _listing['price']?.toString() ?? '0',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _dark,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Description Card
  // ──────────────────────────────────────────
  Widget _buildDescriptionCard() {
    final description = _listing['description']?.toString().trim() ?? '';
    if (description.isEmpty) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.notes_rounded, 'Description'),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _dark,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editListing() async {
    final itemId = _listing['_id']?.toString() ?? '';
    if (itemId.isEmpty) {
      _marketplaceService.showError('Invalid listing');
      return;
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateListingScreen(initialListing: _listing),
      ),
    );

    if (result == true) {
      try {
        final refreshed = await _marketplaceService.getProductDetails(itemId);
        if (!mounted) return;
        setState(() {
          _listing = Map<String, dynamic>.from(refreshed);
          _currentImageIndex = 0;
        });
      } catch (_) {
        // If refresh fails, keep the existing view; the update succeeded.
      }
    }
  }

  // ──────────────────────────────────────────
  // Seller Info Card
  // ──────────────────────────────────────────
  Widget _buildSellerInfoCard() {
    final seller = _listing['seller'] as Map<String, dynamic>?;
    if (seller == null) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.storefront_rounded, 'Seller Information'),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_mid, _dark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _dark.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: seller['shopImage'] != null &&
                          seller['shopImage'].toString().isNotEmpty
                      ? Image.network(seller['shopImage'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.store_rounded,
                              size: 26,
                              color: Colors.white))
                      : const Icon(Icons.store_rounded,
                          size: 26, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller['shopName'] ?? 'AgriCare Shop',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: _dark,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      seller['name'] ?? 'Verified Seller',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _light,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: _mid),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _mid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (seller['email'] != null || seller['phone'] != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: _border),
            const SizedBox(height: 14),
          ],
          if (seller['email'] != null)
            _contactRow(
                Icons.email_rounded, seller['email'], 'example@farm.com'),
          if (seller['email'] != null && seller['phone'] != null)
            const SizedBox(height: 10),
          if (seller['phone'] != null)
            _contactRow(
                Icons.phone_rounded, seller['phone'], '+92 300 0000000'),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String? value, String placeholder) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: _mid),
        ),
        const SizedBox(width: 12),
        Text(
          value?.isNotEmpty == true ? value! : placeholder,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: value?.isNotEmpty == true ? _dark : _light,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Location Card
  // ──────────────────────────────────────────
  Widget _buildLocationCard() {
    final loc = _listing['location'];
    String address = '';
    if (loc is Map) {
      address = loc['address']?.toString().trim() ?? '';
    } else if (loc is String) {
      address = loc.trim();
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.location_on_rounded, 'Location'),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.place_rounded, size: 18, color: _mid),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address.isNotEmpty ? address : 'Lahore, Punjab, Pakistan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: address.isNotEmpty ? _dark : _light,
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // Details Card
  // ──────────────────────────────────────────
  Widget _buildDetailsCard() {
    final createdAt = _listing['createdAt'];
    final quantity = _listing['quantity'];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.info_rounded, 'Listing Details'),
          const SizedBox(height: 16),
          _detailRow(
            icon: Icons.inventory_2_rounded,
            label: 'Quantity',
            value: quantity?.toString(),
            placeholder: 'e.g. 50 kg',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 12),
          _detailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Listed on',
            value: createdAt != null ? _formatDate(createdAt) : null,
            placeholder: 'Date not available',
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    String? value,
    String placeholder = '—',
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: _mid),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _light,
            ),
          ),
        ),
        Text(
          value?.isNotEmpty == true ? value! : placeholder,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: value?.isNotEmpty == true ? _dark : _light,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Shared helpers
  // ──────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _dark.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
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
        Icon(icon, size: 18, color: _mid),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _dark,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) return 'Today';
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      }
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

// ── Status data class ──
class _StatusInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusInfo(this.label, this.color, this.icon);
}