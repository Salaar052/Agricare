// ============================================
// 6. UPDATED SPLASH SCREEN (With Animation)
// lib/screens/splash_screen.dart
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    // Loader animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Check authentication and navigate after 4 seconds
    Timer(const Duration(seconds: 4), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    // Check if user is logged in
    if (authController.isLoggedIn.value) {
      // User is logged in, go to dashboard
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      // User is not logged in, go to login
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🟢 Circular App logo image
                ClipOval(
                  child: Image.asset(
                    'assets/images/pic1.jpg',
                    height: 180,
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 30),

                // 🌿 App Name
                Text(
                  'AgriCare',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 10),

                // 👨‍🌾 Tagline
                Text(
                  'Helping Farmers Grow Smarter 🌿',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 40),

                // 🔄 Loader
                CircularProgressIndicator(
                  color: primaryGreen,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
