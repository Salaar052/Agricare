// ============================================
// 1. AUTH SERVICE (lib/api/auth_service.dart)
// ============================================
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../controllers/auth_controller.dart';
import 'api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.authBase;
  
  final AuthController _authController = Get.find<AuthController>();
  late CookieJar cookieJar;

  AuthService() {
    _initCookieJar();
  }

  // Dedicated exception so UI can route user to verification screen.
  static EmailNotVerifiedException emailNotVerified(String email, String message) {
    return EmailNotVerifiedException(email: email, message: message);
  }

  Future<void> _initCookieJar() async {
    // path_provider is not available on Flutter web
    if (kIsWeb) {
      cookieJar = CookieJar();
      return;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    cookieJar = PersistCookieJar(
      storage: FileStorage("${appDocDir.path}/.cookies/"),
    );
  }

  // Helper to make HTTP requests with better error handling
  Future<http.Response> _makeRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      final mergedHeaders = {...defaultHeaders, ...?headers};

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: mergedHeaders)
              .timeout(const Duration(seconds: 30));
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: mergedHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: mergedHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: mergedHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(const Duration(seconds: 30));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return response;
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server error. Please try again later.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Signup
  // Returns true if backend requires email verification.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('🚀 SignUp - Starting request to: $baseUrl/signup');
      print('📧 Email: $email');
      print('👤 Username: $fullName');
      
      final response = await _makeRequest(
        'POST',
        '$baseUrl/signup',
        body: {
          'username': fullName.trim(),
          'email': email.toLowerCase().trim(),
          'password': password,
        },
      );

      print('📥 SignUp - Response status: ${response.statusCode}');
      print('📥 SignUp - Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          final requiresEmailVerification = data['requiresEmailVerification'] == true;

          // If backend returned a token, store it so we can poll /auth/check.
          if (data['token'] != null) {
            _authController.setUser({
              '_id': data['_id'],
              'username': data['username'],
              'email': data['email'],
              'profileImage': data['profileImage'] ?? '',
              'isAdmin': data['isAdmin'] ?? false,
              'isEmailVerified': data['isEmailVerified'] ?? false,
              'token': data['token'],
            });
          }

          Get.snackbar(
            'Success',
            data['message'] ?? 'Account created successfully!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          return requiresEmailVerification;
        } else {
          throw Exception(data['message'] ?? 'Signup failed');
        }
      } else {
        throw Exception(data['message'] ?? 'Signup failed');
      }
    } catch (e) {
      print('❌ SignUp Error: $e');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      Get.snackbar(
        'Signup Failed',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      rethrow;
    }
  }

  Future<void> resendVerificationEmail({
    required String email,
  }) async {
    final response = await _makeRequest(
      'POST',
      '$baseUrl/resend-verification',
      body: {
        'email': email.toLowerCase().trim(),
      },
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      if (data['success'] == true) {
        Get.snackbar(
          'Email Sent',
          data['message'] ?? 'Verification email sent. Please check your inbox.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        return;
      }
      throw Exception(data['message'] ?? 'Failed to send verification email');
    }

    throw Exception(data['message'] ?? 'Failed to send verification email');
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    final response = await _makeRequest(
      'POST',
      '$baseUrl/forgot-password',
      body: {
        'email': email.toLowerCase().trim(),
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      Get.snackbar(
        'Check Your Email',
        data['message'] ?? 'If an account exists, a reset link has been sent.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    throw Exception(data['message'] ?? 'Failed to request password reset');
  }

  // Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🚀 Login - Starting request to: $baseUrl/login');
      print('📧 Email: $email');

      final response = await _makeRequest(
        'POST',
        '$baseUrl/login',
        body: {
          'email': email.toLowerCase().trim(),
          'password': password,
        },
      );

      print('📥 Login - Response status: ${response.statusCode}');
      print('📥 Login - Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 403 && data is Map && data['code'] == 'EMAIL_NOT_VERIFIED') {
        if (data['token'] != null) {
          _authController.setUser({
            '_id': data['_id'] ?? '',
            'username': data['username'] ?? '',
            'email': data['email'] ?? email.toLowerCase().trim(),
            'profileImage': data['profileImage'] ?? '',
            'isAdmin': data['isAdmin'] ?? false,
            'isEmailVerified': data['isEmailVerified'] ?? false,
            'token': data['token'],
          });
        }
        throw emailNotVerified(email, data['message'] ?? 'Please verify your email.');
      }

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          // Save user data
          _authController.setUser({
            '_id': data['_id'],
            'username': data['username'],
            'email': data['email'],
            'profileImage': data['profileImage'] ?? '',
            'isAdmin': data['isAdmin'] ?? false,
            'isEmailVerified': data['isEmailVerified'] ?? false,
            'token': data['token'],
          });

          Get.snackbar(
            'Success',
            data['message'] ?? 'Login successful!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      Get.snackbar(
        'Login Failed',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      print('🚀 Logout - Starting request');
      
      await _makeRequest(
        'POST',
        '$baseUrl/logout',
        headers: {'Authorization': 'Bearer ${_authController.token.value}'},
      );
      
      print('✅ Logout successful');
    } catch (e) {
      print('⚠️ Logout API error (clearing local data anyway): $e');
    } finally {
      // Always clear local data
      _authController.logout();
      
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Update Profile Image
  Future<void> updateProfileImage(File imageFile) async {
    try {
      print('🚀 Update Profile Image - Starting');
      
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final response = await _makeRequest(
        'PUT',
        '$baseUrl/updateProfileImage',
        headers: {'Authorization': 'Bearer ${_authController.token.value}'},
        body: {'profileImage': base64Image},
      );

      print('📥 Update Profile - Response status: ${response.statusCode}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true && data['updatedUser'] != null) {
          _authController.updateProfileImage(
            data['updatedUser']['profileImage']
          );

          Get.snackbar(
            'Success',
            'Profile image updated!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        } else {
          throw Exception(data['message'] ?? 'Update failed');
        }
      } else {
        throw Exception(data['message'] ?? 'Update failed');
      }
    } catch (e) {
      print('❌ Update Profile Image Error: $e');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      Get.snackbar(
        'Update Failed',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      rethrow;
    }
  }

  // Update admin profile (name and email)
  Future<void> updateAdminProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '$baseUrl/admin/profile',
        headers: {'Authorization': 'Bearer ${_authController.token.value}'},
        body: {
          'username': name.trim(),
          'email': email.toLowerCase().trim(),
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'];
        _authController.updateProfileInfo(
          newUsername: user['username'] ?? name.trim(),
          newEmail: user['email'] ?? email.toLowerCase().trim(),
        );

        Get.snackbar(
          'Success',
          data['message'] ?? 'Profile updated successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      throw Exception(data['message'] ?? 'Failed to update profile');
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Update Failed',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      rethrow;
    }
  }

  // Check Authentication Status
  Future<bool> checkAuth() async {
    try {
      if (_authController.token.value.isEmpty) {
        print('⚠️ No token found');
        return false;
      }

      print('🚀 CheckAuth - Verifying token');

      final response = await _makeRequest(
        'GET',
        '$baseUrl/check',
        headers: {'Authorization': 'Bearer ${_authController.token.value}'},
      );

      print('📥 CheckAuth - Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final user = data['user'];
          if (user is Map && user['isEmailVerified'] != null) {
            _authController.isEmailVerified.value = user['isEmailVerified'] == true;
          }
          print('✅ Token valid');
          return true;
        }
      }

      print('⚠️ Token invalid, logging out');
      _authController.logout();
      return false;
    } catch (e) {
      print('❌ CheckAuth Error: $e');
      _authController.logout();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllFarmersForAdmin() async {
    final response = await _makeRequest(
      'GET',
      '$baseUrl/admin/farmers',
      headers: {'Authorization': 'Bearer ${_authController.token.value}'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final farmers = (data['farmers'] as List<dynamic>? ?? []);
      return farmers.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    throw Exception(data['message'] ?? 'Failed to fetch farmers');
  }

  Future<void> disableSellerAccount(String userId) async {
    final response = await _makeRequest(
      'PUT',
      '$baseUrl/admin/sellers/$userId/disable',
      headers: {'Authorization': 'Bearer ${_authController.token.value}'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      Get.snackbar(
        'Success',
        data['message'] ?? 'Seller account disabled',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    throw Exception(data['message'] ?? 'Failed to disable seller account');
  }

  Future<void> blockUserCompletely(String userId) async {
    final response = await _makeRequest(
      'DELETE',
      '$baseUrl/admin/users/$userId/block',
      headers: {'Authorization': 'Bearer ${_authController.token.value}'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      Get.snackbar(
        'Success',
        data['message'] ?? 'User blocked and data removed',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    throw Exception(data['message'] ?? 'Failed to block user');
  }

  Future<void> deleteSellerAccount(String userId) async {
    final response = await _makeRequest(
      'DELETE',
      '$baseUrl/admin/sellers/$userId',
      headers: {'Authorization': 'Bearer ${_authController.token.value}'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      Get.snackbar(
        'Success',
        data['message'] ?? 'Seller account deleted',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    throw Exception(data['message'] ?? 'Failed to delete seller account');
  }

  Future<void> enableSellerAccount(String userId) async {
    final response = await _makeRequest(
      'PUT',
      '$baseUrl/admin/sellers/$userId/enable',
      headers: {'Authorization': 'Bearer ${_authController.token.value}'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      Get.snackbar(
        'Success',
        data['message'] ?? 'Seller account enabled',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    throw Exception(data['message'] ?? 'Failed to enable seller account');
  }

  Future<Map<String, dynamic>> fetchFarmerDetailsForAdmin(String userId) async {
    final response = await _makeRequest(
      'GET',
      '$baseUrl/admin/farmers/$userId',
      headers: {'Authorization': 'Bearer ${_authController.token.value}'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['farmer'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Failed to fetch farmer details');
  }

  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _makeRequest(
      'PUT',
      '$baseUrl/admin/change-password',
      headers: {'Authorization': 'Bearer ${_authController.token.value}'},
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      Get.snackbar(
        'Success',
        data['message'] ?? 'Password changed successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }
    throw Exception(data['message'] ?? 'Failed to change password');
  }
}

class EmailNotVerifiedException implements Exception {
  final String email;
  final String message;

  EmailNotVerifiedException({
    required this.email,
    required this.message,
  });

  @override
  String toString() => message;
}