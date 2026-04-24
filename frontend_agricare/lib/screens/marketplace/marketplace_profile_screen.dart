// lib/screens/marketplace/marketplace_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/marketplace_service.dart';
import '../../controllers/auth_controller.dart';
import 'your_listings_screen.dart';
import 'saved_items_screen.dart';

class MarketplaceProfileScreen extends StatefulWidget {
  const MarketplaceProfileScreen({super.key});

  @override
  State<MarketplaceProfileScreen> createState() => _MarketplaceProfileScreenState();
}

class _MarketplaceProfileScreenState extends State<MarketplaceProfileScreen> {
  late final MarketplaceService _marketplaceService;
  final AuthController _authController = Get.find<AuthController>();
  
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  int _listingsCount = 0;

  @override
  void initState() {
    super.initState();
    _marketplaceService = MarketplaceService(
      baseUrl: 'http://10.209.229.141:5000/api/v1',
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _marketplaceService.getMyProfile();
      final listings = await _marketplaceService.getMyListings();
      
      setState(() {
        _profile = profile;
        _listingsCount = listings.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _marketplaceService.showError('Failed to load profile');
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
          onPressed: () => Get.offAllNamed('/marketplace'),
        ),
        title: const Text(
          'You',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  
                  // Profile Header
                  _buildProfileHeader(),
                  
                  const SizedBox(height: 8),
                  
                  // Quick Stats
                  _buildQuickStats(),
                  
                  const SizedBox(height: 8),
                  
                  // Selling Section
                  _buildSection(
                    title: 'Selling',
                    items: [
                      _buildMenuItem(
                        icon: Icons.sell_outlined,
                        title: 'Your listings',
                        subtitle: '$_listingsCount items',
                        onTap: () => Get.to(() => const YourListingsScreen()),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Account Section
                  _buildSection(
                    title: 'Account',
                    items: [
                      _buildMenuItem(
                        icon: Icons.verified_user_outlined,
                        title: 'Marketplace access',
                        subtitle: 'You have full access',
                        trailing: const Icon(Icons.check_circle, color: Color(0xFF00A400), size: 20),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        subtitle: _profile?['address'] ?? 'Lahore, Pakistan',
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage your notification settings',
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE4E6EB),
            backgroundImage: _profile?['shopImage'] != null && 
                             _profile!['shopImage'].toString().isNotEmpty
                ? NetworkImage(_profile!['shopImage'])
                : null,
            child: _profile?['shopImage'] == null || 
                   _profile!['shopImage'].toString().isEmpty
                ? const Icon(Icons.store, size: 40, color: Color(0xFF65676B))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?['shopName'] ?? _authController.username.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF050505),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    // View full marketplace profile
                  },
                  child: const Text(
                    'View Marketplace profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1877F2),
                      fontWeight: FontWeight.w600,
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

  Widget _buildQuickStats() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.bookmark_border,
              label: 'Saved items',
              onTap: () => Get.to(() => const SavedItemsScreen()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.inbox_outlined,
              label: 'Inbox',
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: enabled ? const Color(0xFF050505) : const Color(0xFFBCC0C4),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? const Color(0xFF050505) : const Color(0xFFBCC0C4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF050505),
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF050505)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF050505),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF65676B)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(height: 1, color: Color(0xFFE4E6EB)),
    );
  }
}