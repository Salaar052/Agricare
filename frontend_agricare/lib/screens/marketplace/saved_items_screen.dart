// lib/screens/marketplace/saved_items_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/marketplace_service.dart';
import 'product_details_screen.dart';

class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  late final MarketplaceService _marketplaceService;
  
  bool _isLoading = true;
  List<dynamic> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(
      baseUrl: 'http://10.209.229.141:5000/api/v1',
    );
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _marketplaceService.getSavedItems();
      setState(() {
        _savedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load saved items');
    }
  }

  Future<void> _removeSavedItem(String itemId) async {
    try {
      await _marketplaceService.removeFromSavedItems(itemId);
      _loadSavedItems();
    } catch (e) {
      _marketplaceService.showError('Failed to remove item');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Saved items',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSavedItems,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _savedItems.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(_savedItems[index]);
                    },
                  ),
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
            Stack(
              children: [
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
                
                // Unsave Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeSavedItem(product['_id']),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark,
                        size: 20,
                        color: Color(0xFF1877F2),
                      ),
                    ),
                  ),
                ),
              ],
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No saved items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF050505),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Items you save will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF65676B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}