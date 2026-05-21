import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api_config.dart';

class ApiService {
  static final String _advisoryUrl = ApiConfig.advisoryBase;
  static final String _harvestUrl = ApiConfig.harvestBase;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// POST /api/v1/advisory
  static Future<AdvisoryResult> getAdvisory({
    required String crop,
    required SoilInput soil,
    required WeatherInput weather,
  }) async {
    final response = await http.post(
      Uri.parse(_advisoryUrl),
      headers: _headers,
      body: jsonEncode({
        'crop': crop,
        'soil': soil.toJson(),
        'weather': weather.toJson(),
      }),
    );

    if (response.statusCode == 200) {
      return AdvisoryResult.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      if (body['errors'] is List) {
        throw Exception((body['errors'] as List).join('\n'));
      }
      throw Exception(body['error'] ?? 'Failed to get advisory');
    }
  }

  /// POST /api/v1/harvest
  static Future<HarvestResult> getHarvestSuggestion({
    required String crop,
    required List<ForecastDay> forecast,
  }) async {
    final response = await http.post(
      Uri.parse(_harvestUrl),
      headers: _headers,
      body: jsonEncode({
        'crop': crop,
        'forecast': forecast.map((f) => f.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      return HarvestResult.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to get harvest suggestion');
    }
  }
}

// ─── Input Models ─────────────────────────────────────────────────────────────

class SoilInput {
  final double nitrogen;
  final double phosphorus;
  final double potassium;

  const SoilInput({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
  });

  Map<String, dynamic> toJson() => {
    'nitrogen': nitrogen,
    'phosphorus': phosphorus,
    'potassium': potassium,
  };
}

class WeatherInput {
  final double temperature;
  final double humidity;

  const WeatherInput({required this.temperature, required this.humidity});

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
  };
}

class ForecastDay {
  final double temp;
  final double rain;

  const ForecastDay({required this.temp, required this.rain});

  Map<String, dynamic> toJson() => {'temp': temp, 'rain': rain};
}

// ─── Response Models ───────────────────────────────────────────────────────────

class PesticideAdvisory {
  final String issue;
  final String solution;

  const PesticideAdvisory({required this.issue, required this.solution});

  factory PesticideAdvisory.fromJson(Map<String, dynamic> json) =>
      PesticideAdvisory(issue: json['issue'], solution: json['solution']);
}

class AdvisoryResult {
  final String crop;
  final List<String> fertilizers;
  final List<PesticideAdvisory> pesticides;
  final String? cropInsight;
  final String? cropDisplayName;
  final String? aiSummary;
  final bool aiGenerated;

  const AdvisoryResult({
    required this.crop,
    required this.fertilizers,
    required this.pesticides,
    this.cropInsight,
    this.cropDisplayName,
    this.aiSummary,
    this.aiGenerated = false,
  });

  factory AdvisoryResult.fromJson(Map<String, dynamic> json) => AdvisoryResult(
    crop: json['crop'] ?? '',
    fertilizers: List<String>.from(json['fertilizers'] ?? []),
    pesticides: (json['pesticides'] as List? ?? [])
        .map((p) => PesticideAdvisory.fromJson(p))
        .toList(),
    cropInsight: json['cropInsight'] as String?,
    cropDisplayName: json['cropDisplayName'] as String?,
    aiSummary: json['aiSummary'] as String?,
    aiGenerated: json['aiGenerated'] == true,
  );
}

class HarvestResult {
  final String crop;
  final String baseDate;
  final String harvestDate;
  final int adjustmentDays;
  final String advice;
  final String? cropInsight;
  final String? cropDisplayName;

  const HarvestResult({
    required this.crop,
    required this.baseDate,
    required this.harvestDate,
    required this.adjustmentDays,
    required this.advice,
    this.cropInsight,
    this.cropDisplayName,
  });

  factory HarvestResult.fromJson(Map<String, dynamic> json) => HarvestResult(
    crop: json['crop'] ?? '',
    baseDate: json['baseDate'] ?? '',
    harvestDate: json['harvestDate'] ?? '',
    adjustmentDays: json['adjustmentDays'] ?? 0,
    advice: json['advice'] ?? '',
    cropInsight: json['cropInsight'] as String?,
    cropDisplayName: json['cropDisplayName'] as String?,
  );
}
