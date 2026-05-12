// ============================================
// 2. FIXED MARKETPLACE SCREEN (lib/screens/marketplace/marketplace_screen.dart)
// ============================================
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/main_nav_controller.dart';
import '../../controllers/marketplace_account_controller.dart';
import '../../routes/app_routes.dart';
import 'marketplace_main_screen.dart';
import 'marketplace_welcome_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final AuthController _authController = Get.find<AuthController>();

  void _backToDashboard() {
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().goToDashboardRoot();
      return;
    }
    Get.offAllNamed(AppRoutes.dashboard);
  }

  late final MarketplaceAccountController _accountController;
  
  @override
  void initState() {
    super.initState();

    _accountController = Get.isRegistered<MarketplaceAccountController>()
        ? Get.find<MarketplaceAccountController>()
        : Get.put(MarketplaceAccountController(), permanent: true);
    
    // Check if user is logged in first
    if (_authController.token.value.isEmpty) {
      return;
    }

    // Run only once per session (cached in controller)
    _accountController.ensureChecked();
  }

  @override
  Widget build(BuildContext context) {
    // If user isn't logged in, avoid blocking loaders.
    if (_authController.token.value.isEmpty) {
      return const MarketplaceWelcomeScreen();
    }

    return Obx(() {
      final err = _accountController.errorMessage.value;
      if (err.isNotEmpty) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F9F3),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF2D5016),
              ),
              onPressed: _backToDashboard,
              tooltip: 'Back to Dashboard',
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
                    err,
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
                      onPressed: () => _accountController.ensureChecked(force: true),
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

      final resolved = _accountController.haveMarketplaceAccount.value;
      if (resolved == true) {
        return const MarketplaceMainScreen();
      }
      if (resolved == false) {
        return const MarketplaceWelcomeScreen();
      }

      // Initial entry: show a light scaffold with a subtle inline indicator.
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xFF2D5016),
            ),
            onPressed: _backToDashboard,
            tooltip: 'Back to Dashboard',
          ),
          title: Row(
            children: [
              const Text(
                'Marketplace',
                style: TextStyle(
                  color: Color(0xFF2D5016),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              if (_accountController.isChecking.value)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7C2C)),
                  ),
                ),
            ],
          ),
        ),
        body: const Center(
          child: Text(
            'Loading…',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2D5016),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }
}