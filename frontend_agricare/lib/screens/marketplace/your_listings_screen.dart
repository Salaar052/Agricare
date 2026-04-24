// lib/screens/marketplace/your_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/marketplace_service.dart';
import 'create_listing_screen.dart';
import 'view_listing_screen.dart';

class YourListingsScreen extends StatefulWidget {
  const YourListingsScreen({super.key});

  @override
  State<YourListingsScreen> createState() => _YourListingsScreenState();
}

class _YourListingsScreenState extends State<YourListingsScreen> {
  late final MarketplaceService _marketplaceService;
  
  bool _isLoading = true;
  List<dynamic> _listings = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(
      baseUrl: 'http://10.209.229.141:5000/api/v1',
    );
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() => _isLoading = true);
    try {
      final listings = await _marketplaceService.getMyListings();
      setState(() {
        _listings = listings;
        _isLoading = false;
      });
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
          'Your listings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Create Listing Button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Get.to(() => const CreateListingScreen());
                  if (result == true) {
                    _loadListings();
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search your listings',
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
          ),
          
          // Listings
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredListings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadListings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredListings.length,
                          itemBuilder: (context, index) {
                            return _buildListingCard(_filteredListings[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final images = listing['images'] as List? ?? [];
    final imageUrl = images.isNotEmpty ? images[0] : '';
    final status = listing['status'] ?? 'pending';
    final isAvailable = listing['isAvailable'] ?? false;
    final isSold = listing['isSold'] ?? false;
    
    String statusText = 'Pending approval';
    Color statusColor = const Color(0xFFF59E0B);
    
    if (status == 'approved') {
      if (isSold) {
        statusText = 'Sold';
        statusColor = const Color(0xFF65676B);
      } else if (!isAvailable) {
        statusText = 'Out of stock';
        statusColor = const Color(0xFFEF4444);
      } else {
        statusText = 'Available';
        statusColor = const Color(0xFF00A400);
      }
    } else if (status == 'rejected') {
      statusText = 'Rejected';
      statusColor = const Color(0xFFEF4444);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showListingOptions(listing),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFFF0F2F5),
                          child: const Icon(Icons.image, size: 30, color: Color(0xFFBCC0C4)),
                        ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF050505),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${listing['price']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF050505),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.more_horiz, color: Color(0xFF65676B)),
            ],
          ),
        ),
      ),
    );
  }

  void _showListingOptions(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View listing'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => ViewListingScreen(listing: listing));
              },
            ),
            if (listing['status'] != 'approved' || !(listing['isSold'] ?? false))
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit listing'),
                onTap: () {
                  Navigator.pop(context);
                  _marketplaceService.showSuccess('Edit feature coming soon!');
                },
              ),
            if (listing['status'] == 'approved' && !(listing['isSold'] ?? false))
              ListTile(
                leading: Icon(
                  listing['isAvailable'] ? Icons.remove_circle_outline : Icons.check_circle_outline,
                ),
                title: Text(listing['isAvailable'] ? 'Mark as out of stock' : 'Mark as in stock'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _marketplaceService.updateMyListing(
                      itemId: listing['_id'],
                      isAvailable: !(listing['isAvailable'] ?? false),
                    );
                    _loadListings();
                  } catch (e) {
                    _marketplaceService.showError('Failed to update listing');
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
              title: const Text('Delete listing', style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(listing);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete listing?'),
        content: Text('Are you sure you want to delete "${listing['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _marketplaceService.deleteMyListing(listing['_id']);
                _loadListings();
              } catch (e) {
                _marketplaceService.showError('Failed to delete listing');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
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
            Icon(Icons.sell_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No listings yet' : 'No listings found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF050505),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create your first listing to start selling'
                  : 'Try adjusting your search',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF65676B),
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Get.to(() => const CreateListingScreen());
                  if (result == true) {
                    _loadListings();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create listing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}