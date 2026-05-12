// ============================================================
// api_service.dart — Backend API Communication
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';
import '../../models/garden_recommendation/plant_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  /// Calls POST /api/recommend-plants and returns structured results.
  Future<RecommendationResponse> getRecommendations(
    RecommendationRequest request,
  ) async {
    try {
      final uri = Uri.parse(AppConstants.recommendEndpoint);

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RecommendationResponse.fromJson(json);
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errors =
            (json['errors'] as List?)?.join(', ') ?? 'Invalid input.';
        return RecommendationResponse.error(errors);
      } else {
        return RecommendationResponse.error(
          'Server error (${response.statusCode}). Please try again.',
        );
      }
    } on Exception catch (e) {
      return RecommendationResponse.error(
        'Could not connect to server. Make sure the backend is running.\n\nDetails: $e',
      );
    }
  }
}
