// ============================================
// 2. FIXED MARKETPLACE SCREEN (lib/screens/marketplace/marketplace_screen.dart)
// ============================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/marketplace_service.dart';
import '../../controllers/auth_controller.dart';
import 'marketplace_main_screen.dart';
import 'marketplace_welcome_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late final MarketplaceService _marketplaceService;
  final AuthController _authController = Get.find<AuthController>();
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMarketplaceAccount = false;

  @override
  void initState() {
    super.initState();
    
    // ⚠️ IMPORTANT: Update with your laptop's IP address
    _marketplaceService = MarketplaceService(
      baseUrl: 'http://10.209.229.141:5000/api/v1', // ← Change this to your IP
    );
    
    // Check if user is logged in first
    if (_authController.token.value.isEmpty) {
      print('⚠️ WARNING: No token found. User may not be logged in!');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Please login first';
      });
      return;
    }
    
    print('✅ Token found: ${_authController.token.value.substring(0, 20)}...');
    _checkMarketplaceAccount();
  }

  Future<void> _checkMarketplaceAccount() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      print('🔍 Starting marketplace account check...');
      print('👤 User: ${_authController.username.value}');
      print('📧 Email: ${_authController.email.value}');
      
      final hasAccount = await _marketplaceService.checkMarketplaceAccount();
      
      print('✅ Account check complete. Result: $hasAccount');
      
      if (!mounted) return;
      
      setState(() {
        _hasMarketplaceAccount = hasAccount;
        _isLoading = false;
      });
      
      print('🎉 UI updated successfully');
    } catch (e) {
      print('❌ Error in account check: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9F3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7C2C)),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Checking marketplace account...',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF2D5016).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error screen
    if (_hasError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5016)),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Marketplace',
            style: TextStyle(
              color: Color(0xFF2D5016),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF5350), width: 2),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Connection Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _checkMarketplaceAccount,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7C2C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Route to appropriate screen
    print('🚀 Routing to: ${_hasMarketplaceAccount ? "Products Screen" : "Welcome Screen"}');
    
    return _hasMarketplaceAccount 
        ? const MarketplaceMainScreen() 
        : const MarketplaceWelcomeScreen();
  }
}