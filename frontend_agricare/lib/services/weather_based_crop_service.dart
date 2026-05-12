import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_config.dart';

class WeatherBasedCropService {
  String get _apiUrl => ApiConfig.apiV1('/crop-recommendation/weather-based');

  Future<Map<String, dynamic>> recommend({
    required double lat,
    required double lng,
    String? locationLabel,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(_apiUrl);

    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    final response = await http
        .post(
          uri,
          headers: mergedHeaders,
          body: jsonEncode({
            'lat': lat,
            'lng': lng,
            if (locationLabel != null && locationLabel.trim().isNotEmpty)
              'locationLabel': locationLabel.trim(),
          }),
        )
        .timeout(const Duration(seconds: 45));

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid server response');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final msg = (data['error'] ?? data['message'] ?? 'Request failed').toString();
    throw Exception(msg);
  }
}
