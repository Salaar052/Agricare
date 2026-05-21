import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';

class CropRecommendationApi {
  static const Duration _submitTimeout = Duration(seconds: 20);
  static const Duration _pollInterval = Duration(milliseconds: 650);
  static const Duration _maxPollTime = Duration(seconds: 35);

  // Mirror of agricare-ml-service/ml_service.py CROP_DICT.
  // Some deployments return a numeric class index instead of the crop label.
  static const Map<int, String> _cropDict = {
    1: 'rice',
    2: 'maize',
    3: 'chickpea',
    4: 'kidneybeans',
    5: 'pigeonpeas',
    6: 'mothbeans',
    7: 'mungbean',
    8: 'blackgram',
    9: 'lentil',
    10: 'pomegranate',
    11: 'banana',
    12: 'mango',
    13: 'grapes',
    14: 'watermelon',
    15: 'muskmelon',
    16: 'apple',
    17: 'orange',
    18: 'papaya',
    19: 'coconut',
    20: 'cotton',
    21: 'jute',
    22: 'coffee',
  };

  /// Calls the HF Gradio 6.x two-step API.
  ///
  /// Returns a map shaped like the legacy backend response so existing UI works:
  /// {
  ///   "success": true,
  ///   "crop": "rice",
  ///   "recommended_crop": "rice",
  ///   "confidence": 95.0, // percent
  /// }
  static Future<Map<String, dynamic>> predict({
    required num n,
    required num p,
    required num k,
    required num temperature,
    required num humidity,
    required num ph,
    required num rainfall,
    http.Client? client,
  }) async {
    final http.Client httpClient = client ?? http.Client();
    try {
      final submitUri = Uri.parse('${ApiConfig.mlOrigin}/gradio_api/call/predict');
      final submitBody = jsonEncode({
        'data': [
          n,
          p,
          k,
          temperature,
          humidity,
          ph,
          rainfall,
        ],
      });

      final submitResponse = await httpClient
          .post(
            submitUri,
            headers: const {'Content-Type': 'application/json'},
            body: submitBody,
          )
          .timeout(
            _submitTimeout,
            onTimeout: () => throw TimeoutException(
              'Timed out while submitting request to ML service.',
            ),
          );

      if (submitResponse.statusCode < 200 || submitResponse.statusCode >= 300) {
        throw Exception(
          'ML submit failed (HTTP ${submitResponse.statusCode}).',
        );
      }

      final submitJson = _tryDecodeJson(submitResponse.body);
      final eventId = (submitJson is Map)
          ? (submitJson['event_id'] ?? submitJson['eventId'])
          : null;

      if (eventId == null || eventId.toString().trim().isEmpty) {
        throw Exception('ML submit did not return a valid event_id.');
      }

      final String eventIdStr = eventId.toString().trim();
      final resultUri = Uri.parse(
        '${ApiConfig.mlOrigin}/gradio_api/call/predict/$eventIdStr',
      );

      final started = DateTime.now();
      String? lastDataLine;

      while (DateTime.now().difference(started) < _maxPollTime) {
        final res = await httpClient.get(resultUri);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception('ML result fetch failed (HTTP ${res.statusCode}).');
        }

        final body = res.body;

        // SSE format lines like:
        // event: complete
        // data: ["rice",0.95]
        final parsed = _parseSse(body);
        if (parsed.lastData != null) {
          lastDataLine = parsed.lastData;
        }

        if (parsed.isComplete) {
          final dataLine = parsed.completeData ?? lastDataLine;
          if (dataLine == null || dataLine.trim().isEmpty) {
            throw Exception('ML service completed but returned no data.');
          }

          final decoded = _tryDecodeJson(dataLine.trim());
          final cropAndConfidence = _extractCropAndConfidence(decoded);

          final crop = cropAndConfidence.$1;
          final confidencePercent = cropAndConfidence.$2;

          return {
            'success': true,
            'crop': crop,
            'recommended_crop': crop,
            'confidence': confidencePercent,
          };
        }

        if (parsed.isError) {
          final dataLine = parsed.errorData ?? lastDataLine;
          final msg = (dataLine != null && dataLine.trim().isNotEmpty)
              ? dataLine.trim()
              : 'ML service returned an error.';
          throw Exception(msg);
        }

        await Future.delayed(_pollInterval);
      }

      throw TimeoutException('Timed out waiting for ML result.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  static (String crop, double confidencePercent) _extractCropAndConfidence(
    Object? decoded,
  ) {
    if (decoded is List && decoded.isNotEmpty) {
      final rawCrop = decoded.first;
      final crop = _normalizeCropLabel(rawCrop);
      if (crop.isEmpty) throw Exception('ML response missing crop name.');

      double conf = 0.0;
      if (decoded.length >= 2) {
        final raw = decoded[1];
        if (raw is num) {
          conf = raw.toDouble();
        } else {
          conf = double.tryParse(raw.toString()) ?? 0.0;
        }
      }

      // Gradio commonly returns 0..1; UI expects percent.
      final confidencePercent = (conf <= 1.0) ? (conf * 100.0) : conf;
      return (crop, confidencePercent);
    }

    // Some Gradio apps may wrap output differently.
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is List) {
        return _extractCropAndConfidence(data);
      }
    }

    throw Exception('Unexpected ML response format.');
  }

  static String _normalizeCropLabel(Object? raw) {
    if (raw == null) return '';

    // If Gradio returns a number (or numeric string), map it to a crop name.
    int? index;
    if (raw is int) {
      index = raw;
    } else if (raw is num) {
      // Handle values like 1.0
      final asInt = raw.toInt();
      if ((raw - asInt).abs() < 1e-9) index = asInt;
    } else {
      final s = raw.toString().trim();
      if (s.isEmpty) return '';
      final parsed = int.tryParse(s);
      if (parsed != null) {
        index = parsed;
      } else {
        final parsedDouble = double.tryParse(s);
        if (parsedDouble != null) {
          final asInt = parsedDouble.toInt();
          if ((parsedDouble - asInt).abs() < 1e-9) {
            index = asInt;
          }
        }

        if (index != null) {
          // continue to mapping
        } else {
        // Already a label like "rice".
        return s;
        }
      }
    }

    if (index == null) return raw.toString().trim();

    // Prefer 1-based mapping; fall back to 0-based mapping.
    final direct = _cropDict[index];
    if (direct != null) return direct;
    final plusOne = _cropDict[index + 1];
    if (plusOne != null) return plusOne;

    return 'Unknown crop';
  }

  static Object? _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  static _SseParseResult _parseSse(String body) {
    final lines = const LineSplitter().convert(body);
    String? currentEvent;
    String? lastData;
    String? completeData;
    String? errorData;

    bool sawComplete = false;
    bool sawError = false;

    for (final raw in lines) {
      final line = raw.trimRight();
      if (line.startsWith('event:')) {
        currentEvent = line.substring('event:'.length).trim();
        if (currentEvent == 'complete') sawComplete = true;
        if (currentEvent == 'error') sawError = true;
      } else if (line.startsWith('data:')) {
        final data = line.substring('data:'.length).trim();
        lastData = data;

        if (currentEvent == 'complete') {
          completeData = data;
        } else if (currentEvent == 'error') {
          errorData = data;
        }
      }
    }

    // Fallback: some responses include the token without proper event ordering.
    if (body.contains('event: complete')) sawComplete = true;
    if (body.contains('event: error')) sawError = true;

    return _SseParseResult(
      isComplete: sawComplete,
      isError: sawError,
      lastData: lastData,
      completeData: completeData,
      errorData: errorData,
    );
  }
}

class _SseParseResult {
  final bool isComplete;
  final bool isError;
  final String? lastData;
  final String? completeData;
  final String? errorData;

  const _SseParseResult({
    required this.isComplete,
    required this.isError,
    required this.lastData,
    required this.completeData,
    required this.errorData,
  });
}
