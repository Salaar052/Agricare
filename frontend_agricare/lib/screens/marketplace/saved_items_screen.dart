// lib/screens/marketplace/saved_items_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/marketplace_service.dart';
import 'product_details_screen.dart';
import 'marketplace_main_screen.dart'; // ← ADDED
import '../../api/api_config.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;

  bool _isLoading = true;
  List<dynamic> _savedItems = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ── Theme ──
  static const Color _primary   = Color(0xFF2D5016);
  static const Color _secondary = Color(0xFF4A7C2C);
  static const Color _accent    = Color(0xFF6AAF3D);
  static const Color _surface   = Color(0xFFF5F9F3);
  static const Color _textDark  = Color(0xFF1A2E0D);
  static const Color _textMid   = Color(0xFF4A5E3A);
  static const Color _textLight = Color(0xFF8FA882);
  static const Color _divider   = Color(0xFFE8F0E4);
  static const Color _bgPage    = Color(0xFFF0F4EE);

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);

    _fadeController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
    _loadSavedItems();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _marketplaceService.getSavedItems();
      setState(() {
        _savedItems = items;
        _isLoading  = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load saved items');
    }
  }

  Future<void> _removeSavedItem(String itemId) async {
    HapticFeedback.mediumImpact();
    try {
      await _marketplaceService.removeFromSavedItems(itemId);
      _loadSavedItems();
    } catch (e) {
      _marketplaceService.showError('Failed to remove item');
    }
  }

  // ────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) =>
                [_buildSliverAppBar(innerBoxIsScrolled)],
            body: _isLoading
                ? _buildLoadingState()
                : _savedItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadSavedItems,
                        color: _secondary,
                        backgroundColor: Colors.white,
                        child: _buildGrid(),
                      ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────
  // APP BAR
  // ────────────────────────────────────────────
 Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
  return SliverAppBar(
    toolbarHeight: 70,
    floating: true,
    pinned: true,
    elevation: 0,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,

    automaticallyImplyLeading: false,

    leadingWidth: 60,

    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: _AnimatedIconButton(
        onTap: () => Navigator.of(context).pop(),
        icon: Icons.arrow_back_ios_new_rounded,
        color: _primary,
      ),
    ),

    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Saved Items',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'AgriCare Marketplace',
          style: TextStyle(
            color: _textLight,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),

    centerTitle: true,

    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: _AnimatedIconButton(
          onTap: _loadSavedItems,
          icon: Icons.refresh_rounded,
          color: _secondary,
        ),
      ),
    ],

    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        color: _divider,
      ),
    ),
  );
}
  // ────────────────────────────────────────────
  // GRID
  // ────────────────────────────────────────────
  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth  = (constraints.maxWidth - 14 * 2 - 12) / 2;
        final cardHeight = cardWidth + 88.0;
        final ratio      = cardWidth / cardHeight;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildStatsHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: ratio,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildProductCard(_savedItems[index], index),
                  childCount: _savedItems.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_secondary, _accent]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _secondary.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${_savedItems.length} Saved',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Tap to view details',
            style: TextStyle(
              fontSize: 12,
              color: _textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // PRODUCT CARD WRAPPER
  // ────────────────────────────────────────────
  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final images   = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] as String : '';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: _ProductCardTile(
        product: product,
        imageUrl: imageUrl,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(productId: product['_id']),
            ),
          );
        },
        onRemove: () => _removeSavedItem(product['_id'] as String),
      ),
    );
  }

  // ────────────────────────────────────────────
  // LOADING
  // ────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_secondary, _accent]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _secondary.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(15),
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Loading saved items…',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textMid,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────
  // EMPTY STATE
  // ────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_surface, const Color(0xFFDCEDD6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _divider, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 44, color: _secondary),
            ),
            const SizedBox(height: 26),
            const Text(
              'Nothing saved yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Browse the marketplace and tap the\nbookmark icon to save items here.',
              style: TextStyle(
                fontSize: 14,
                color: _textLight,
                fontWeight: FontWeight.w500,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              // ── FIXED: navigates to MarketplaceMainScreen ──
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const MarketplaceMainScreen(),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_primary, _secondary]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _secondary.withOpacity(0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 17),
                    SizedBox(width: 8),
                    Text(
                      'Browse Marketplace',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
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
}

// ──────────────────────────────────────────────────────────────────────────────
// PRODUCT CARD TILE
// ──────────────────────────────────────────────────────────────────────────────
class _ProductCardTile extends StatefulWidget {
  final Map<String, dynamic> product;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ProductCardTile({
    required this.product,
    required this.imageUrl,
    required this.onTap,
    required this.onRemove,
  });

  @override
  State<_ProductCardTile> createState() => _ProductCardTileState();
}

class _ProductCardTileState extends State<_ProductCardTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bookmarkCtrl;
  late final Animation<double>   _bookmarkScale;
  bool _pressed = false;

  static const Color _secondary = Color(0xFF4A7C2C);
  static const Color _accent    = Color(0xFF6AAF3D);
  static const Color _surface   = Color(0xFFF5F9F3);
  static const Color _textDark  = Color(0xFF1A2E0D);
  static const Color _textMid   = Color(0xFF4A5E3A);
  static const Color _textLight = Color(0xFF8FA882);

  @override
  void initState() {
    super.initState();
    _bookmarkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _bookmarkScale = Tween<double>(begin: 1.0, end: 0.72)
        .animate(CurvedAnimation(parent: _bookmarkCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bookmarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D5016).withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: SizedBox.expand(
                        child: widget.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                    ),

                    // Bottom gradient
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.30),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Condition badge
                    if (widget.product['condition'] != null)
                      Positioned(
                        bottom: 7, left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_secondary, _accent]),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            widget.product['condition']
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),

                    // Bookmark button
                    Positioned(
                      top: 7, right: 7,
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await _bookmarkCtrl.forward();
                          await _bookmarkCtrl.reverse();
                          widget.onRemove();
                        },
                        child: ScaleTransition(
                          scale: _bookmarkScale,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.11),
                                  blurRadius: 7,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.bookmark_rounded,
                                size: 16, color: _secondary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info section ──
              SizedBox(
                height: 88,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${widget.product["price"] ?? "—"}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.product['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textMid,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                size: 10, color: _secondary),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (widget.product['location']
                                      ?['address'] as String?) ??
                                  'Lahore',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _textLight,
                                height: 1.1,
                              ),
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
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _surface,
      child: const Center(
        child: Icon(Icons.image_not_supported_rounded,
            size: 36, color: Color(0xFF8FA882)),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// ANIMATED ICON BUTTON
// ──────────────────────────────────────────────────────────────────────────────
class _AnimatedIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;

  const _AnimatedIconButton({
    required this.onTap,
    required this.icon,
    required this.color,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9F3),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(widget.icon, color: widget.color, size: 19),
        ),
      ),
    );
  }
}