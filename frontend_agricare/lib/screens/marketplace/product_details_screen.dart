// lib/screens/marketplace/product_details_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../services/marketplace_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final MarketplaceService _marketplaceService;
  final CarouselSliderController _carouselController = CarouselSliderController();
  
  bool _isLoading = true;
  Map<String, dynamic>? _product;
  List<dynamic> _relatedProducts = [];
  bool _isSaved = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(
      baseUrl: 'http://10.209.229.141:5000/api/v1',
    );
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await _marketplaceService.getProductDetails(widget.productId);
      
      // Load related products
      final relatedResult = await _marketplaceService.getAllItems(
        category: product['category'],
        limit: 10,
      );
      
      // Check if saved
      final savedItems = await _marketplaceService.getSavedItems();
      final isSaved = savedItems.any((item) => item['_id'] == widget.productId);
      
      setState(() {
        _product = product;
        _relatedProducts = (relatedResult['items'] ?? [])
            .where((item) => item['_id'] != widget.productId)
            .take(6)
            .toList();
        _isSaved = isSaved;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load product');
    }
  }

  Future<void> _toggleSave() async {
    try {
      if (_isSaved) {
        await _marketplaceService.removeFromSavedItems(widget.productId);
        _marketplaceService.showSuccess('Removed from saved items');
      } else {
        await _marketplaceService.addToSavedItems(widget.productId);
        _marketplaceService.showSuccess('Added to saved items');
      }
      setState(() => _isSaved = !_isSaved);
    } catch (e) {
      _marketplaceService.showError('Failed to update saved items');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Color(0xFF65676B)),
              const SizedBox(height: 16),
              const Text(
                'Product not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final images = _product!['images'] as List? ?? [];
    final seller = _product!['sellerId'] as Map<String, dynamic>?;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Carousel
          _buildSliverAppBar(images),
          
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // Price & Title Card
                _buildPriceTitleCard(),
                
                const SizedBox(height: 8),
                
                // Description Card
                if (_product!['description'] != null && 
                    _product!['description'].toString().trim().isNotEmpty)
                  _buildDescriptionCard(),
                
                const SizedBox(height: 8),
                
                // Seller Info Card
                if (seller != null) _buildSellerInfoCard(seller),
                
                const SizedBox(height: 8),
                
                // Product Details Card
                _buildProductDetailsCard(),
                
                const SizedBox(height: 8),
                
                // Related Items
                if (_relatedProducts.isNotEmpty) _buildRelatedItemsSection(),
                
                const SizedBox(height: 100), // Bottom padding for fixed bar
              ],
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildSliverAppBar(List images) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
          onPressed: () => Get.back(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? const Color(0xFF1877F2) : Colors.black,
              size: 22,
            ),
            onPressed: _toggleSave,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.black, size: 22),
            onPressed: () {
              // Share functionality
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? Stack(
                children: [
                  CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: images.length,
                    itemBuilder: (context, index, realIndex) {
                      return Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1877F2),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF0F2F5),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Color(0xFFBCC0C4),
                                ),
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
                  
                  // Image Counter Badge
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  
                  // Dot Indicators
                  if (images.length > 1)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
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
                color: const Color(0xFFF0F2F5),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Color(0xFFBCC0C4),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPriceTitleCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.currency_rupee,
                size: 28,
                color: Color(0xFF00A400),
              ),
              Text(
                _product!['price']?.toString() ?? '0',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _product!['title'] ?? 'Untitled Product',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF050505),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _product!['category'] ?? 'General',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1877F2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: Color(0xFF65676B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _product!['location']?['address'] ?? 'Lahore, Pakistan',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF65676B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, size: 20, color: Color(0xFF65676B)),
              SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _product!['description']?.toString().trim() ?? '',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF050505),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfoCard(Map<String, dynamic> seller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.store, size: 20, color: Color(0xFF65676B)),
              SizedBox(width: 8),
              Text(
                'Seller Information',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE4E6EB),
                backgroundImage: seller['shopImage'] != null && 
                    seller['shopImage'].toString().isNotEmpty
                    ? NetworkImage(seller['shopImage'])
                    : null,
                child: seller['shopImage'] == null || 
                    seller['shopImage'].toString().isEmpty
                    ? const Icon(
                        Icons.store,
                        color: Color(0xFF65676B),
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller['shopName'] ?? 'Unknown Shop',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF050505),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${_formatDate(_product!['createdAt'])}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF65676B),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard() {
    final quantity = _product!['quantity'];
    final createdAt = _product!['createdAt'];
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Color(0xFF65676B)),
              SizedBox(width: 8),
              Text(
                'Product Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (quantity != null) ...[
            _buildDetailRow('Quantity Available', quantity.toString()),
            const SizedBox(height: 12),
          ],
          if (createdAt != null)
            _buildDetailRow('Listed', _formatDate(createdAt)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF65676B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF050505),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              Icon(Icons.grid_view, size: 20, color: Color(0xFF65676B)),
              SizedBox(width: 8),
              Text(
                'Related Items',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF050505),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.only(bottom: 20),
          child: SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _relatedProducts.length,
              itemBuilder: (context, index) {
                return _buildRelatedItem(_relatedProducts[index]);
              },
            ),
          ),
        ),
        Container(
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedItem(Map<String, dynamic> product) {
    final images = product['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    
    return GestureDetector(
      onTap: () {
        // Navigate to the new product, replacing current screen
        Get.off(
          () => ProductDetailsScreen(productId: product['_id']),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 300),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E6EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 160,
                width: 160,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFE4E6EB),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1877F2),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFE4E6EB),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Color(0xFFBCC0C4),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFFE4E6EB),
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Color(0xFFBCC0C4),
                        ),
                      ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rs ${product['price']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF050505),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF65676B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          // Save Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _toggleSave,
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
              ),
              label: Text(_isSaved ? 'Saved' : 'Save'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: _isSaved ? const Color(0xFF1877F2) : const Color(0xFFCED0D4),
                  width: 1.5,
                ),
                foregroundColor: _isSaved ? const Color(0xFF1877F2) : const Color(0xFF050505),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Message Seller Button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                // Message seller functionality
                _marketplaceService.showSuccess('Messaging feature coming soon!');
              },
              icon: const Icon(Icons.message, size: 20),
              label: const Text('Message seller'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'recently';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      
      if (diff == 0) return 'today';
      if (diff == 1) return 'yesterday';
      if (diff < 7) return '$diff days ago';
      if (diff < 30) return '${(diff / 7).floor()} ${(diff / 7).floor() == 1 ? 'week' : 'weeks'} ago';
      if (diff < 365) return '${(diff / 30).floor()} ${(diff / 30).floor() == 1 ? 'month' : 'months'} ago';
      return '${(diff / 365).floor()} ${(diff / 365).floor() == 1 ? 'year' : 'years'} ago';
    } catch (e) {
      return 'recently';
    }
  }
}