// ============================================
// 1. AUTH SERVICE (lib/api/auth_service.dart)
// ============================================
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../controllers/auth_controller.dart';

class AuthService {
  // IMPORTANT: Change this to your actual backend URL
  // For Android Emulator: use 10.0.2.2
  // For iOS Simulator: use localhost or 127.0.0.1
  // For Physical Device: use your computer's IP (e.g., 192.168.x.x)
  static const String baseUrl = 'http://localhost:8000/api/v1/auth';
  
  final AuthController _authController = Get.find<AuthController>();
  late CookieJar cookieJar;

  AuthService() {
    _initCookieJar();
  }

  Future<void> _initCookieJar() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    cookieJar = PersistCookieJar(
      storage: FileStorage("${appDocDir.path}/.cookies/")
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
  Future<void> signUp({
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
          // Save user data
          _authController.setUser({
            '_id': data['_id'],
            'username': data['username'],
            'email': data['email'],
            'profileImage': data['profileImage'] ?? '',
            'token': data['token'],
          });

          Get.snackbar(
            'Success',
            data['message'] ?? 'Account created successfully!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
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

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          // Save user data
          _authController.setUser({
            '_id': data['_id'],
            'username': data['username'],
            'email': data['email'],
            'profileImage': data['profileImage'] ?? '',
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
}