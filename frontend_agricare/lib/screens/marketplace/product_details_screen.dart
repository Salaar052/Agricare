// lib/screens/marketplace/product_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/marketplace_service.dart';
import '../../api/api_config.dart';
import 'view_seller_profile_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;
  final CarouselSliderController _carouselController = CarouselSliderController();

  bool _isLoading = true;
  Map<String, dynamic>? _product;
  List<dynamic> _relatedProducts = [];
  bool _isSaved = false;
  bool _isSaveLoading = false; // ✅ debounce flag
  int _currentImageIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ── Design tokens ──────────────────────────
  static const Color _primary   = Color(0xFF1B3A0F);
  static const Color _secondary = Color(0xFF3A6B1E);
  static const Color _accent    = Color(0xFF5A9E30);
  static const Color _bg        = Color(0xFFEFF4EC);
  static const Color _card      = Colors.white;
  static const Color _textDark  = Color(0xFF152B09);
  static const Color _textMid   = Color(0xFF4A5E3A);
  static const Color _textLight = Color(0xFF8FA882);
  static const Color _border    = Color(0xFFE2EDD9);
  static const Color _gold      = Color(0xFFC8932A);

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);

    _fadeController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));

    _fadeAnimation  = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _loadProduct();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product       = await _marketplaceService.getProductDetails(widget.productId);
      final relatedResult = await _marketplaceService.getAllItems(category: product['category'], limit: 10);
      final savedItems    = await _marketplaceService.getSavedItems();
      final isSaved       = savedItems.any((item) => item['_id'] == widget.productId);

      setState(() {
        _product = product;
        _relatedProducts = (relatedResult['items'] ?? [])
            .where((item) => item['_id'] != widget.productId)
            .take(6)
            .toList();
        _isSaved   = isSaved;
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showToast('Failed to load product', isError: true);
    }
  }

  // ✅ Debounced save toggle — prevents duplicate messages
  Future<void> _toggleSave() async {
    if (_isSaveLoading) return; // block if already in flight
    HapticFeedback.mediumImpact();
    setState(() => _isSaveLoading = true);

    final wasAlreadySaved = _isSaved;
    // Optimistic update
    setState(() => _isSaved = !_isSaved);

    try {
      if (wasAlreadySaved) {
        await _marketplaceService.removeFromSavedItems(widget.productId, showToast: false);
        _showToast('Removed from saved items');
      } else {
        await _marketplaceService.addToSavedItems(widget.productId, showToast: false);
        _showToast('Saved to your list');
      }
    } catch (e) {
      // Revert on failure
      setState(() => _isSaved = wasAlreadySaved);
      _showToast('Could not update saved items', isError: true);
    } finally {
      setState(() => _isSaveLoading = false);
    }
  }

  // ✅ Clean custom toast — no GetX snackbar conflicts
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFB23B3B) : _secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  void _openSellerProfile() {
    final seller = _product?['sellerId'] as Map<String, dynamic>?;
    if (seller == null) return;
    final sellerId = seller['_id']?.toString() ?? '';
    if (sellerId.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ViewSellerProfileScreen(sellerId: sellerId),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _openWhatsAppChat() async {
    final seller    = _product?['sellerId'] as Map<String, dynamic>?;
    final rawNumber = seller?['whatsapp_number']?.toString().trim() ?? '';
    final digits    = rawNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _showToast('Seller WhatsApp not available', isError: true);
      return;
    }

    final productName = _product?['title']?.toString().trim() ?? 'this product';
    final message =
        'Hello, I am interested in your product "$productName" listed on AgriCare Marketplace. Could you please provide more details?';

    final url = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}');
    final ok  = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) _showToast('Could not open WhatsApp', isError: true);
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScaffold();
    if (_product == null) return _buildErrorScaffold();

    final images = _product!['images'] as List? ?? [];
    final seller = _product!['sellerId'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(images),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainInfoSection(),
                    _buildDividerGap(),
                    if (_product!['description']?.toString().trim().isNotEmpty == true)
                      ...[_buildDescriptionSection(), _buildDividerGap()],
                    if (seller != null)
                      ...[_buildSellerSection(seller), _buildDividerGap()],
                    _buildDetailsSection(),
                    if (_relatedProducts.isNotEmpty)
                      ...[_buildDividerGap(), _buildRelatedSection()],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDividerGap() => Container(height: 8, color: _bg);

  // ─────────────────────────────────────────
  // LOADING / ERROR
  // ─────────────────────────────────────────
  Widget _buildLoadingScaffold() => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: _bg, elevation: 0,
      leading: _BackButton(),
    ),
    body: const Center(
      child: CircularProgressIndicator(color: _secondary, strokeWidth: 2.5),
    ),
  );

  Widget _buildErrorScaffold() => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: _bg, elevation: 0,
      leading: _BackButton(),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off_rounded, size: 34, color: _textLight),
            ),
            const SizedBox(height: 20),
            const Text('Product not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
            const SizedBox(height: 6),
            const Text(
              'This listing may have been removed or is no longer available.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: _textLight, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );

  // ─────────────────────────────────────────
  // SLIVER APP BAR
  // ─────────────────────────────────────────
  Widget _buildSliverAppBar(List images) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: _card,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleIconBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildImageCarousel(images),
        collapseMode: CollapseMode.pin,
      ),
    );
  }

  Widget _buildImageCarousel(List images) {
    if (images.isEmpty) {
      return Container(
        color: const Color(0xFFE8F0E4),
        child: const Center(
          child: Icon(Icons.image_not_supported_rounded, size: 56, color: _textLight),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: images.length,
          itemBuilder: (context, index, realIndex) => Image.network(
            images[index],
            fit: BoxFit.cover,
            width: double.infinity,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : Container(
                    color: const Color(0xFFE8F0E4),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: _secondary),
                    ),
                  ),
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE8F0E4),
              child: const Center(
                child: Icon(Icons.image_not_supported_rounded, size: 56, color: _textLight),
              ),
            ),
          ),
          options: CarouselOptions(
            height: 320,
            viewportFraction: 1.0,
            enableInfiniteScroll: images.length > 1,
            onPageChanged: (i, _) => setState(() => _currentImageIndex = i),
          ),
        ),

        // Bottom gradient
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
              ),
            ),
          ),
        ),

        // Dot indicators
        if (images.length > 1)
          Positioned(
            bottom: 14, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = _currentImageIndex == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 20 : 6, height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

        // Count pill
        if (images.length > 1)
          Positioned(
            bottom: 10, right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${images.length}',
                style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // MAIN INFO
  // ─────────────────────────────────────────
  Widget _buildMainInfoSection() {
    final condition = _product!['condition']?.toString();
    final itemLocation = _product!['location'];
    final location = (itemLocation is Map ? itemLocation['address'] : null)?.toString().trim().isNotEmpty == true
      ? (itemLocation as Map)['address'].toString().trim()
      : ((_product!['sellerId'] is Map)
        ? ((_product!['sellerId'] as Map)['address']?.toString().trim())
        : null);

    return Container(
      width: double.infinity, // ✅ full width always
      color: _card,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Condition badge + price in same row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'PKR ${_formatPrice(_product!['price'])}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
              if (condition != null) ...[
                const SizedBox(width: 10),
                _ConditionBadge(condition: condition),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Title — full width, no wrapping clipped by container
          Text(
            _product!['title'] ?? 'Untitled Product',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 14),

          // Category chips — wrap properly
          if (_product!['category'] != null || _product!['subcategory'] != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_product!['category'] != null)
                  _TagChip(label: _product!['category'], icon: Icons.category_outlined),
                if (_product!['subcategory'] != null)
                  _TagChip(label: _product!['subcategory'], icon: Icons.subdirectory_arrow_right_rounded),
              ],
            ),

          // Location row (only if present)
          if (location != null && location.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7EF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: _secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textMid,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // DESCRIPTION — full width, flexible height
  // ─────────────────────────────────────────
  Widget _buildDescriptionSection() {
    final desc = _product!['description']?.toString().trim() ?? '';
    return Container(
      width: double.infinity,
      color: _card,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Description'),
          const SizedBox(height: 12),
          // ✅ Text fills width naturally — no artificial sizing
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14.5,
              color: _textMid,
              height: 1.75,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SELLER
  // ─────────────────────────────────────────
  Widget _buildSellerSection(Map<String, dynamic> seller) {
    return Container(
      width: double.infinity,
      color: _card,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Seller'),
          const SizedBox(height: 14),
          // ✅ Tappable seller row — full width, properly constrained
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openSellerProfile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7EF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    // Avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: seller['shopImage'] != null &&
                              seller['shopImage'].toString().isNotEmpty
                          ? Image.network(
                              seller['shopImage'],
                              width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _SellerAvatarFallback(),
                            )
                          : _SellerAvatarFallback(),
                    ),
                    const SizedBox(width: 14),
                    // Name + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            seller['shopName'] ?? 'Unknown Shop',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Listed ${_formatDate(_product!['createdAt'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // View profile chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // DETAILS — always full width rows
  // ─────────────────────────────────────────
  Widget _buildDetailsSection() {
    final quantity  = _product!['quantity'];
    final createdAt = _product!['createdAt'];
    final condition = _product!['condition'];

    final rows = <Map<String, String>>[];
    if (condition != null)
      rows.add({'label': 'Condition', 'value': condition.toString()});
    if (quantity != null)
      rows.add({'label': 'Quantity', 'value': quantity.toString()});
    if (createdAt != null)
      rows.add({'label': 'Listed', 'value': _formatDate(createdAt)});

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: _card,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Details'),
          const SizedBox(height: 14),
          // ✅ Each row is full width with spaceBetween
          ...List.generate(rows.length, (i) {
            final isLast = i == rows.length - 1;
            return Column(
              children: [
                _DetailRow(label: rows[i]['label']!, value: rows[i]['value']!),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  const Divider(color: _border, height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // RELATED ITEMS
  // ─────────────────────────────────────────
  Widget _buildRelatedSection() {
    return Container(
      color: _card,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Related Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${_relatedProducts.length} items',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              itemCount: _relatedProducts.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 280 + index * 45),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(12 * (1 - v), 0),
                      child: child,
                    ),
                  ),
                  child: _RelatedCard(
                    product: _relatedProducts[index],
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ProductDetailsScreen(
                            productId: _relatedProducts[index]['_id'],
                          ),
                          transitionDuration: const Duration(milliseconds: 260),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Save button with loading state + debounce
          _SaveButton(
            isSaved: _isSaved,
            isLoading: _isSaveLoading,
            onTap: _toggleSave,
          ),
          const SizedBox(width: 12),

          // WhatsApp button
          _WhatsAppButton(onTap: _openWhatsAppChat),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final num p = price is num ? price : num.tryParse(price.toString()) ?? 0;
    if (p >= 1000000) return '${(p / 1000000).toStringAsFixed(1)}M';
    if (p >= 1000) {
      final formatted = p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return formatted;
    }
    return p.toStringAsFixed(0);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'recently';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date).inDays;
      if (diff == 0) return 'today';
      if (diff == 1) return 'yesterday';
      if (diff < 7)  return '$diff days ago';
      if (diff < 30) return '${(diff / 7).floor()}w ago';
      if (diff < 365) return '${(diff / 30).floor()}mo ago';
      return '${(diff / 365).floor()}y ago';
    } catch (_) {
      return 'recently';
    }
  }
}

// ─────────────────────────────────────────
// SAVE BUTTON — clean debounced widget
// ─────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final bool isLoading;
  final VoidCallback onTap;

  static const Color _secondary = Color(0xFF3A6B1E);
  static const Color _bg       = Color(0xFFEFF4EC);
  static const Color _border   = Color(0xFFE2EDD9);
  static const Color _textMid  = Color(0xFF4A5E3A);

  const _SaveButton({
    required this.isSaved,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: isSaved ? _secondary.withOpacity(0.1) : _bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSaved ? _secondary.withOpacity(0.5) : _border,
            width: 1.5,
          ),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _secondary,
                  ),
                ),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  key: ValueKey(isSaved),
                  color: isSaved ? _secondary : _textMid,
                  size: 22,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// WHATSAPP BUTTON
// ─────────────────────────────────────────
class _WhatsAppButton extends StatefulWidget {
  final VoidCallback onTap;
  const _WhatsAppButton({required this.onTap});

  @override
  State<_WhatsAppButton> createState() => _WhatsAppButtonState();
}

class _WhatsAppButtonState extends State<_WhatsAppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  static const Color _secondary = Color(0xFF3A6B1E);
  static const Color _border   = Color(0xFFE2EDD9);

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown:   (_) { HapticFeedback.lightImpact(); _ctrl.forward(); },
        onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                FaIcon(FontAwesomeIcons.whatsapp, size: 20, color: Color(0xFF25D366)),
                SizedBox(width: 10),
                Text(
                  'Contact Seller',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _secondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8FA882),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Color(0xFFE2EDD9), height: 1)),
      ],
    );
  }
}

// ─────────────────────────────────────────
// DETAIL ROW — full width spaceBetween
// ─────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8FA882),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF152B09),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// TAG CHIP
// ─────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TagChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7EC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCDE4C0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF3A6B1E)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A6B1E),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CONDITION BADGE
// ─────────────────────────────────────────
class _ConditionBadge extends StatelessWidget {
  final String condition;
  const _ConditionBadge({required this.condition});

  @override
  Widget build(BuildContext context) {
    final isNew = condition.toLowerCase() == 'new';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFE4F4D8) : const Color(0xFFF5F0E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNew ? const Color(0xFFB5DAA0) : const Color(0xFFDACC9A),
        ),
      ),
      child: Text(
        isNew ? 'Brand New' : 'Used',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: isNew ? const Color(0xFF2A5C10) : const Color(0xFF6B5200),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// SELLER AVATAR FALLBACK
// ─────────────────────────────────────────
class _SellerAvatarFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFD4EAD0),
      ),
      child: const Icon(Icons.storefront_outlined, color: Color(0xFF3A6B1E), size: 24),
    );
  }
}

// ─────────────────────────────────────────
// CIRCLE ICON BUTTON
// ─────────────────────────────────────────
class _CircleIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  const _CircleIconBtn({required this.icon, required this.onTap, this.bg = Colors.white});

  @override
  State<_CircleIconBtn> createState() => _CircleIconBtnState();
}

class _CircleIconBtnState extends State<_CircleIconBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: widget.bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(widget.icon, size: 17, color: const Color(0xFF152B09)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// RELATED CARD
// ─────────────────────────────────────────
class _RelatedCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  const _RelatedCard({required this.product, required this.onTap});

  @override
  State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final images   = widget.product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0].toString() : '';
    final price    = widget.product['price'];

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          width: 148,
          margin: const EdgeInsets.only(right: 12, bottom: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2EDD9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image — fixed height, no overflow
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  height: 120, width: 148,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) => p == null
                              ? child
                              : Container(
                                  color: const Color(0xFFE8F0E4),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF3A6B1E),
                                    ),
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE8F0E4),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 28,
                              color: Color(0xFF8FA882),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE8F0E4),
                          child: const Icon(
                            Icons.image_outlined,
                            size: 28,
                            color: Color(0xFF8FA882),
                          ),
                        ),
                ),
              ),
              // Text content
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PKR $price',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3A0F),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.product['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF4A5E3A),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BACK BUTTON
// ─────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF152B09)),
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}