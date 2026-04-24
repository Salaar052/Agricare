// lib/screens/marketplace/marketplace_main_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/marketplace_service.dart';
import 'product_details_screen.dart';
import 'marketplace_profile_screen.dart';

class MarketplaceMainScreen extends StatefulWidget {
  const MarketplaceMainScreen({super.key});

  @override
  State<MarketplaceMainScreen> createState() => _MarketplaceMainScreenState();
}

class _MarketplaceMainScreenState extends State<MarketplaceMainScreen> {
  late final MarketplaceService _marketplaceService;
  
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  List<dynamic> _products = [];
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Seeds', 'icon': '🌱'},
    {'name': 'Fertilizers', 'icon': '🧪'},
    {'name': 'Pesticides', 'icon': '💊'},
    {'name': 'Machinery', 'icon': '🚜'},
    {'name': 'Livestock', 'icon': '🐄'},
  ];

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(
      baseUrl: 'http://10.209.229.141:5000/api/v1',
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _marketplaceService.getAllItems(
        category: _selectedCategory,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _products = result['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
    // Always go back to dashboard instead of closing the app
    Get.offAllNamed('/dashboard');  
    return false; // stop default back behavior
  },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Search Bar
              _buildSearchBar(),
              
              // Category Filter
              _buildCategoryFilter(),
              
              // Products Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                        ? _buildEmptyState()
                        : _buildProductsGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Marketplace',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C1E21),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Get.to(() => const MarketplaceProfileScreen()),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE4E6EB),
              child: const Icon(Icons.person, size: 20, color: Color(0xFF050505)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadProducts();
        },
        decoration: InputDecoration(
          hintText: 'Search Marketplace',
          hintStyle: const TextStyle(color: Color(0xFF65676B)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF65676B)),
          filled: true,
          fillColor: const Color(0xFFF0F2F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = isSelected ? null : category['name'];
              });
              _loadProducts();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1877F2) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1877F2) : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF050505),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.66,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    
    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsScreen(productId: product['_id'])),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFF0F2F5),
                        child: const Icon(Icons.image, size: 50, color: Color(0xFFBCC0C4)),
                      ),
              ),
            ),
            
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      'Rs ${product['price']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF050505),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Title
                    Text(
                      product['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF65676B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Color(0xFF65676B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product['location']?['address'] ?? 'Lahore',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF65676B),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}