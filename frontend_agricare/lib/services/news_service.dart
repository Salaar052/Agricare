import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../controllers/auth_controller.dart';
import '../models/news/news_model.dart';

class NewsService {
  final String baseUrl; // ApiConfig.apiV1Base
  final AuthController _authController = Get.find<AuthController>();

  NewsService({required this.baseUrl});

  Map<String, String> _jsonHeaders({bool auth = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      headers['Authorization'] = 'Bearer ${_authController.token.value}';
    }
    return headers;
  }

  Map<String, dynamic> _parseJson(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      final msg = data is Map ? (data['message'] ?? data['error'] ?? 'Request failed') : 'Request failed';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to parse server response');
    }
  }

  void showError(String message) {
    final clean = message.replaceAll('Exception: ', '').trim();
    Get.snackbar(
      'Error',
      clean.isEmpty ? 'Something went wrong' : clean,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.85),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  Future<List<NewsModel>> getNews({int page = 1, int limit = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/news').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final resp = await http.get(uri, headers: _jsonHeaders()).timeout(const Duration(seconds: 30));
      final data = _parseJson(resp);
      final items = (data['data']?['items'] as List?) ?? const [];
      return items.map((e) => NewsModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<NewsModel> getNewsById(String id) async {
    if (id.trim().isEmpty) throw Exception('News id is required');

    final uri = Uri.parse('$baseUrl/news/$id');
    final resp = await http.get(uri, headers: _jsonHeaders()).timeout(const Duration(seconds: 30));
    final data = _parseJson(resp);
    final map = Map<String, dynamic>.from(data['data']?['news'] ?? {});
    return NewsModel.fromJson(map);
  }

  Future<NewsModel> createNews({
    required String headlineEn,
    required String headlineUr,
    required String descriptionEn,
    required String descriptionUr,
    List<File>? imageFiles,
    File? imageFile,
    bool isPublished = true,
    String language = 'both',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/news');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer ${_authController.token.value}';

      request.fields['headlineEn'] = headlineEn.trim();
      request.fields['headlineUr'] = headlineUr.trim();
      request.fields['descriptionEn'] = descriptionEn.trim();
      request.fields['descriptionUr'] = descriptionUr.trim();
      request.fields['language'] = language;
      request.fields['isPublished'] = isPublished ? 'true' : 'false';

      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (final f in imageFiles) {
          request.files.add(await http.MultipartFile.fromPath('images', f.path));
        }
      } else if (imageFile != null) {
        // legacy single-image support
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(streamed);
      final data = _parseJson(resp);

      final map = Map<String, dynamic>.from(data['data']?['news'] ?? {});
      return NewsModel.fromJson(map);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> deleteNews(String id) async {
    if (id.trim().isEmpty) throw Exception('News id is required');

    final uri = Uri.parse('$baseUrl/news/$id');
    final resp = await http
        .delete(uri, headers: _jsonHeaders(auth: true))
        .timeout(const Duration(seconds: 30));

    _parseJson(resp);
  }
}
