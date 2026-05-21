// lib/screens/marketplace/marketplace_main_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/main_nav_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/marketplace_service.dart';
import 'create_listing_screen.dart';
import 'product_details_screen.dart';
import 'marketplace_profile_screen.dart';
import 'your_listings_screen.dart';
import '../../api/api_config.dart';

class MarketplaceMainScreen extends StatefulWidget {
  const MarketplaceMainScreen({super.key});

  @override
  State<MarketplaceMainScreen> createState() => _MarketplaceMainScreenState();
}

class _MarketplaceMainScreenState extends State<MarketplaceMainScreen>
    with TickerProviderStateMixin {
  late final MarketplaceService _marketplaceService;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _loadSeq = 0;

  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  List<dynamic> _products = [];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Seeds', 'icon': Icons.grass_rounded},
    {'name': 'Fertilizers', 'icon': Icons.science_rounded},
    {'name': 'Pesticides', 'icon': Icons.bug_report_rounded},
    {'name': 'Machinery', 'icon': Icons.agriculture_rounded},
    {'name': 'Livestock', 'icon': Icons.pets_rounded},
  ];

  late AnimationController _enterController;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(baseUrl: ApiConfig.apiV1Base);
    _loadProducts();

    _enterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _enterController.forward();

    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _enterController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final int requestId = ++_loadSeq;
    setState(() => _isLoading = true);
    try {
      final result = await _marketplaceService.getAllItems(
        category: _selectedCategory,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );
      if (!mounted || requestId != _loadSeq) return;
      setState(() {
        _products = result['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _loadSeq) return;
      setState(() => _isLoading = false);
    }
  }

  void _backToDashboard() {
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().goToDashboardRoot();
      return;
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        tooltip: 'Add new listing',
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateListingScreen(),
            ),
          );

          if (result == true) {
            if (!mounted) return;
            await _loadProducts();

            if (!mounted) return;
            // After publish, take the user to their own listings where
            // newly created items (often pending approval) are visible.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const YourListingsScreen(),
              ),
            );
          }
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildCategorySection()),
                  _isLoading
                      ? SliverFillRemaining(child: _buildLoadingState())
                      : _products.isEmpty
                          ? SliverFillRemaining(child: _buildEmptyState())
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.72,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _buildProductCard(_products[index]),
                                  childCount: _products.length,
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

  Widget _buildHeader() {
    return Container(
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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D5016),
              size: 20,
            ),
            onPressed: _backToDashboard,
            tooltip: 'Back to Dashboard',
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agri-Store',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016)),
              ),
              Text(
                'Premium Farming Solutions',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: Color(0xFF2D5016)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MarketplaceProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0EED4)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) {
            _searchQuery = v;
            _searchDebounce?.cancel();
            _searchDebounce =
                Timer(const Duration(milliseconds: 500), _loadProducts);
          },
          decoration: const InputDecoration(
            hintText: 'Search products...',
            prefixIcon: Icon(Icons.search, color: Color(0xFF4A7C2C)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory != null
                    ? '$_selectedCategory Category'
                    : 'All Categories',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016)),
              ),
              GestureDetector(
  onTap: () {
    final hasFilters =
        _selectedCategory != null || _searchQuery.trim().isNotEmpty;

    if (!hasFilters) return;

    setState(() {
      _selectedCategory = null;
      _searchQuery = '';
      _searchController.clear();
    });

    _loadProducts();
  },
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity:
        (_selectedCategory != null || _searchQuery.trim().isNotEmpty)
            ? 1.0
            : 0.45,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5EF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE0EED4),
        ),
      ),
      child: const Icon(
        Icons.filter_alt_off_rounded,
        size: 20,
        color: Color(0xFF4A7C2C),
      ),
    ),
  ),
),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : cat['name'];
                  });
                  _loadProducts();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF4A7C2C), Color(0xFF2D5016)])
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFE0EED4)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: const Color(0xFF2D5016).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(cat['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        cat['name'],
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _resolveProductLocation(Map<String, dynamic> product) {
    final location = product['location'];
    if (location is Map) {
      final address = (location['address'] ?? '').toString().trim();
      if (address.isNotEmpty) return address;
    }

    final seller = product['sellerId'];
    if (seller is Map) {
      final address = (seller['address'] ?? '').toString().trim();
      if (address.isNotEmpty) return address;
    }

    return 'Location not available';
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: product['_id']),
          ),
        );
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        width: double.infinity, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFF1F5EF), child: const Icon(Icons.image, color: Colors.white)),
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'Rs ${product['price']}',
                      style: const TextStyle(
                          color: Color(0xFF2D5016),
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _resolveProductLocation(product),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF4A7C2C)));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No products found", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}