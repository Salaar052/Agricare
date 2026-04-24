// ============================================
// lib/services/marketplace_service.dart
// Professional marketplace service with error handling
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class MarketplaceService {
  final String baseUrl;
  final AuthController _authController = Get.find<AuthController>();

  MarketplaceService({required this.baseUrl});

  // Helper: Get auth headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${_authController.token.value}',
    };
  }

  // Helper: Make HTTP request with comprehensive error handling
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = _getHeaders();

      print('🌐 Making $method request to: $uri');
      if (body != null) print('📤 Request body: ${json.encode(body)}');

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: body != null ? json.encode(body) : null)
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: body != null ? json.encode(body) : null)
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      return response;
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server error. Please try again later.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } on TimeoutException {
      throw Exception('Connection timeout. Please try again.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. Please try again.');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Helper: Parse response
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final message = data['message'] ?? 'Request failed';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse server response');
    }
  }

  // ==================== MARKETPLACE ACCOUNT ====================

  /// Check if user has marketplace account
  Future<bool> checkMarketplaceAccount() async {
    try {
      print('🔍 Checking marketplace account...');
      
      final response = await _makeRequest('GET', '/marketplace/check-account');
      final data = _parseResponse(response);
      
      // Extract boolean from response - supports both old and new response formats
      final hasAccount = data['data']?['haveMarketplaceAccount'] ?? false;
      
      print('✅ Has marketplace account: $hasAccount');
      return hasAccount;
    } catch (e) {
      print('❌ Check account error: $e');
      rethrow;
    }
  }

  /// Register marketplace account
  Future<Map<String, dynamic>> registerMarketplaceAccount({
    required String shopName,
    required String address,
    String? shopDescription,
    String? sellerBio,
    String? shopImage,
    Map<String, dynamic>? geoLocation,
  }) async {
    try {
      print('🚀 Registering marketplace account...');
      print('📝 Shop Name: $shopName');
      print('📍 Address: $address');
      
      if (shopName.trim().isEmpty) {
        throw Exception('Shop name is required');
      }
      
      if (address.trim().isEmpty) {
        throw Exception('Address is required');
      }

      final response = await _makeRequest('POST', '/marketplace/register', body: {
        'shopName': shopName.trim(),
        'shopDescription': shopDescription?.trim() ?? '',
        'sellerBio': sellerBio?.trim() ?? '',
        'address': address.trim(),
        'shopImage': shopImage ?? '',
        'geoLocation': geoLocation ?? {
          'type': 'Point',
          'coordinates': [0.0, 0.0],
        },
      });

      final data = _parseResponse(response);
      print('✅ Marketplace account registered successfully');
      
      showSuccess('Marketplace account created successfully!');
      
      return data['data'] ?? {};
    } catch (e) {
      print('❌ Register account error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  // ==================== ITEMS / PRODUCTS ====================

  /// Get all marketplace items with pagination
  Future<Map<String, dynamic>> getAllItems({
    int page = 1,
    int limit = 20,
    String? category,
    String? subcategory,
    String? search,
  }) async {
    try {
      print('📦 Fetching items - Page: $page, Limit: $limit');
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
        print('🏷️ Category filter: $category');
      }
      if (subcategory != null && subcategory.isNotEmpty) {
        queryParams['subcategory'] = subcategory;
        print('🏷️ Subcategory filter: $subcategory');
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
        print('🔍 Search query: $search');
      }

      final uri = Uri.parse('$baseUrl/marketplace/items').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders()).timeout(const Duration(seconds: 30));
      
      final data = _parseResponse(response);
      final itemCount = data['data']?['items']?.length ?? 0;
      final totalItems = data['data']?['pagination']?['totalItems'] ?? 0;
      
      print('✅ Fetched $itemCount items (Total: $totalItems)');
      
      return data['data'] ?? {};
    } catch (e) {
      print('❌ Fetch items error: $e');
      rethrow;
    }
  }

  /// Get single product details
  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    try {
      print('🔍 Fetching product details: $productId');
      
      if (productId.isEmpty) {
        throw Exception('Product ID is required');
      }

      final response = await _makeRequest('GET', '/marketplace/items/$productId');
      final data = _parseResponse(response);
      
      print('✅ Product details fetched');
      return data['data']?['item'] ?? {};
    } catch (e) {
      print('❌ Fetch product error: $e');
      rethrow;
    }
  }

  // ==================== MY PROFILE ====================

  /// Get my marketplace profile
  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      print('👤 Fetching my marketplace profile...');
      
      final response = await _makeRequest('GET', '/marketplace/my-profile');
      final data = _parseResponse(response);
      
      print('✅ Profile fetched');
      return data['data']?['profile'] ?? {};
    } catch (e) {
      print('❌ Fetch profile error: $e');
      rethrow;
    }
  }

  /// Edit my marketplace profile
  Future<Map<String, dynamic>> editMyProfile({
    String? shopName,
    String? shopDescription,
    String? sellerBio,
    String? shopImage,
    String? address,
    Map<String, dynamic>? geoLocation,
    bool? isActive,
  }) async {
    try {
      print('✏️ Updating marketplace profile...');
      
      final body = <String, dynamic>{};
      
      if (shopName != null && shopName.trim().isNotEmpty) {
        body['shopName'] = shopName.trim();
      }
      if (shopDescription != null) {
        body['shopDescription'] = shopDescription.trim();
      }
      if (sellerBio != null) {
        body['sellerBio'] = sellerBio.trim();
      }
      if (shopImage != null) body['shopImage'] = shopImage;
      if (address != null) body['address'] = address.trim();
      if (geoLocation != null) body['geoLocation'] = geoLocation;
      if (isActive != null) body['isActive'] = isActive;

      if (body.isEmpty) {
        throw Exception('No changes to update');
      }

      final response = await _makeRequest('PUT', '/marketplace/my-profile', body: body);
      final data = _parseResponse(response);
      
      print('✅ Profile updated');
      showSuccess('Profile updated successfully!');
      
      return data['data']?['profile'] ?? {};
    } catch (e) {
      print('❌ Update profile error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  // ==================== SAVED ITEMS ====================

  /// Get saved items
  Future<List<dynamic>> getSavedItems() async {
    try {
      print('💾 Fetching saved items...');
      
      final response = await _makeRequest('GET', '/marketplace/saved-items');
      final data = _parseResponse(response);
      
      final savedItems = data['data']?['savedItems'] ?? [];
      print('✅ Fetched ${savedItems.length} saved items');
      
      return savedItems;
    } catch (e) {
      print('❌ Fetch saved items error: $e');
      rethrow;
    }
  }

  /// Add item to saved
  Future<void> addToSavedItems(String itemId) async {
    try {
      print('💾 Adding item to saved: $itemId');
      
      if (itemId.isEmpty) {
        throw Exception('Item ID is required');
      }

      await _makeRequest('POST', '/marketplace/saved-items', body: {'itemId': itemId});
      
      print('✅ Item added to saved');
      showSuccess('Item saved successfully!');
    } catch (e) {
      print('❌ Add to saved error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  /// Remove item from saved
  Future<void> removeFromSavedItems(String itemId) async {
    try {
      print('🗑️ Removing item from saved: $itemId');
      
      if (itemId.isEmpty) {
        throw Exception('Item ID is required');
      }

      await _makeRequest('DELETE', '/marketplace/saved-items/$itemId');
      
      print('✅ Item removed from saved');
      showSuccess('Item removed from saved!');
    } catch (e) {
      print('❌ Remove from saved error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  // ==================== SELLER PROFILE ====================

  /// Get seller profile (public view)
  Future<Map<String, dynamic>> getSellerProfile(String sellerId) async {
    try {
      print('👤 Fetching seller profile: $sellerId');
      
      if (sellerId.isEmpty) {
        throw Exception('Seller ID is required');
      }

      final response = await _makeRequest('GET', '/marketplace/seller/$sellerId');
      final data = _parseResponse(response);
      
      print('✅ Seller profile fetched');
      return data['data']?['seller'] ?? {};
    } catch (e) {
      print('❌ Fetch seller profile error: $e');
      rethrow;
    }
  }

  // ==================== MY LISTINGS ====================

  /// Get my listings
  Future<List<dynamic>> getMyListings({String? status}) async {
    try {
      print('📋 Fetching my listings...');
      if (status != null) print('🏷️ Status filter: $status');
      
      String endpoint = '/marketplace/my-listings';
      if (status != null && status.isNotEmpty) {
        endpoint += '?status=$status';
      }

      final response = await _makeRequest('GET', endpoint);
      final data = _parseResponse(response);
      
      final items = data['data']?['items'] ?? [];
      print('✅ Fetched ${items.length} listings');
      
      return items;
    } catch (e) {
      print('❌ Fetch listings error: $e');
      rethrow;
    }
  }

  /// Create new listing
  Future<Map<String, dynamic>> createNewListing({
    required String title,
    required String category,
    required String subcategory,
    required double price,
    String? description,
    List<String>? images,
    String? condition,
    Map<String, dynamic>? location,
  }) async {
    try {
      print('🆕 Creating new listing...');
      print('📝 Title: $title');
      print('💰 Price: \$$price');
      
      if (title.trim().isEmpty) throw Exception('Title is required');
      if (category.isEmpty) throw Exception('Category is required');
      if (subcategory.isEmpty) throw Exception('Subcategory is required');
      if (price <= 0) throw Exception('Price must be greater than 0');

      final response = await _makeRequest('POST', '/marketplace/listings', body: {
        'title': title.trim(),
        'category': category,
        'subcategory': subcategory,
        'price': price,
        'description': description?.trim() ?? '',
        'images': images ?? [],
        'condition': condition ?? 'new',
        'location': location,
      });

      final data = _parseResponse(response);
      print('✅ Listing created successfully');
      
      showSuccess('Listing created successfully! Awaiting admin approval.');
      
      return data['data']?['item'] ?? {};
    } catch (e) {
      print('❌ Create listing error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  /// Update my listing
  Future<Map<String, dynamic>> updateMyListing({
    required String itemId,
    String? title,
    String? category,
    String? subcategory,
    double? price,
    String? description,
    List<String>? images,
    String? condition,
    Map<String, dynamic>? location,
    bool? isAvailable,
  }) async {
    try {
      print('✏️ Updating listing: $itemId');
      
      if (itemId.isEmpty) throw Exception('Item ID is required');

      final body = <String, dynamic>{};
      
      if (title != null && title.trim().isNotEmpty) body['title'] = title.trim();
      if (category != null) body['category'] = category;
      if (subcategory != null) body['subcategory'] = subcategory;
      if (price != null && price > 0) body['price'] = price;
      if (description != null) body['description'] = description.trim();
      if (images != null) body['images'] = images;
      if (condition != null) body['condition'] = condition;
      if (location != null) body['location'] = location;
      if (isAvailable != null) body['isAvailable'] = isAvailable;

      if (body.isEmpty) throw Exception('No changes to update');

      final response = await _makeRequest('PUT', '/marketplace/my-listings/$itemId', body: body);
      final data = _parseResponse(response);
      
      print('✅ Listing updated');
      showSuccess('Listing updated successfully!');
      
      return data['data']?['item'] ?? {};
    } catch (e) {
      print('❌ Update listing error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  /// Delete my listing
  Future<void> deleteMyListing(String itemId) async {
    try {
      print('🗑️ Deleting listing: $itemId');
      
      if (itemId.isEmpty) throw Exception('Item ID is required');

      await _makeRequest('DELETE', '/marketplace/my-listings/$itemId');
      
      print('✅ Listing deleted');
      showSuccess('Listing deleted successfully!');
    } catch (e) {
      print('❌ Delete listing error: $e');
      showError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Show success message
  void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF4A7C2C).withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// Show error message
  void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFD32F2F).withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }
}