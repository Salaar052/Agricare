// ============================================
// DEMO PROFILE SCREEN
// Shows how to access AuthController data anywhere
// lib/screens/profile/profile_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../api/auth_service.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  // Access the auth controller - that's it! No Provider setup needed
  final AuthController authController = Get.find<AuthController>();
  final AuthService authService = AuthService();

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Color(0xFF4A7C2C)),
            onPressed: () {
              Get.snackbar(
                'Edit Profile',
                'Edit functionality coming soon!',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  // Profile Image - Using Obx to react to changes
                  Obx(() {
                    if (authController.hasProfileImage) {
                      return CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          authController.profileImage.value,
                        ),
                      );
                    } else {
                      // Fallback with first letter of username
                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFF4A7C2C),
                        child: Text(
                          authController.username.value.isNotEmpty
                              ? authController.username.value[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                  }),
                  SizedBox(height: 16),

                  // Username - Using Obx to react to changes
                  Obx(
                    () => Text(
                      authController.username.value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Email - Using Obx to react to changes
                  Obx(
                    () => Text(
                      authController.email.value,
                      style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Login Status Badge
                  Obx(
                    () => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: authController.isLoggedIn.value
                            ? Color(0xFF10B981).withOpacity(0.1)
                            : Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: authController.isLoggedIn.value
                                ? Color(0xFF10B981)
                                : Color(0xFFEF4444),
                          ),
                          SizedBox(width: 6),
                          Text(
                            authController.isLoggedIn.value
                                ? 'Active'
                                : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: authController.isLoggedIn.value
                                  ? Color(0xFF10B981)
                                  : Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // User Data Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 16),

                  // User ID
                  _buildInfoCard(
                    icon: Icons.fingerprint,
                    label: 'User ID',
                    value: Obx(
                      () => Text(
                        authController.userId.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    color: Color(0xFF3B82F6),
                  ),

                  // Email
                  _buildInfoCard(
                    icon: Icons.email,
                    label: 'Email Address',
                    value: Obx(
                      () => Text(
                        authController.email.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    color: Color(0xFF8B5CF6),
                  ),

                  // Username
                  _buildInfoCard(
                    icon: Icons.person,
                    label: 'Username',
                    value: Obx(
                      () => Text(
                        authController.username.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    color: Color(0xFF10B981),
                  ),

                  // Token Preview (first 30 chars)
                  _buildInfoCard(
                    icon: Icons.vpn_key,
                    label: 'Auth Token',
                    value: Obx(
                      () => Text(
                        authController.token.value.isNotEmpty
                            ? '${authController.token.value.substring(0, 30)}...'
                            : 'No token',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    color: Color(0xFFF59E0B),
                  ),

                  SizedBox(height: 24),

                  // Actions Section
                  Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Refresh Data Button
                  _buildActionButton(
                    icon: Icons.refresh,
                    label: 'Refresh Profile Data',
                    color: Color(0xFF3B82F6),
                    onTap: () {
                      // Reload user data from storage
                      authController.loadUser();
                      Get.snackbar(
                        'Success',
                        'Profile data refreshed!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Color(0xFF10B981),
                        colorText: Colors.white,
                      );
                    },
                  ),

                  // View Token Button (for testing)
                  _buildActionButton(
                    icon: Icons.code,
                    label: 'View Full Token',
                    color: Color(0xFF8B5CF6),
                    onTap: () {
                      Get.dialog(
                        Dialog(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Auth Token',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close),
                                      onPressed: () => Get.back(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SelectableText(
                                    authController.token.value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Clear Storage Button (for testing)
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Clear Local Storage',
                    color: Color(0xFFEF4444),
                    onTap: () {
                      Get.dialog(
                        AlertDialog(
                          title: Text('Clear Storage?'),
                          content: Text(
                            'This will log you out and clear all stored data.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                authController.logout();
                                Get.back();
                                Get.offAllNamed(AppRoutes.login);
                              },
                              child: Text(
                                'Clear',
                                style: TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await authService.logout();
                        Get.offAllNamed(AppRoutes.login);
                      },
                      icon: Icon(Icons.logout),
                      label: Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEF4444),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required Widget value,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
