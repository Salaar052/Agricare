  import 'dart:io' show Platform;

  import 'package:flutter/foundation.dart' show kIsWeb;

  class ApiConfig {
    /// Single place to set your backend URL for a REAL PHONE.
    /// Make sure to include scheme and port.
    /// Example: 'http://192.168.100.9:5000'
    static const String defaultBackendOrigin = 'http://127.0.0.1:5000';

    /// Crop recommendation ML service (HF Space)
    static const String defaultMlOrigin =
        'https://aqeelsaeed-crop-recommendation-api.hf.space';

    /// Android emulator reaches your PC via 10.0.2.2.
    /// For a REAL phone, set this to false and use `BACKEND_ORIGIN` with your PC's LAN IP.
    /// Example:
    /// `flutter run --dart-define=USE_ANDROID_EMULATOR=false --dart-define=BACKEND_ORIGIN=http://192.168.1.10:5000`
    static const bool useAndroidEmulator =
        bool.fromEnvironment('USE_ANDROID_EMULATOR', defaultValue: true);

    /// Override at runtime, e.g.
    /// `flutter run --dart-define=BACKEND_ORIGIN=http://192.168.1.10:5000`
    static const String _backendOriginOverride = String.fromEnvironment(
      'BACKEND_ORIGIN',
    );

    /// Override at runtime, e.g.
    /// `flutter run --dart-define=ML_ORIGIN=https://...hf.space`
    static const String _mlOriginOverride = String.fromEnvironment(
      'ML_ORIGIN',
    );

    static const int _defaultPort = int.fromEnvironment('BACKEND_PORT', defaultValue: 5000);

    static String _normalizeOrigin(String origin) {
      final o = origin.trim();
      if (o.endsWith('/')) return o.substring(0, o.length - 1);
      return o;
    }

    static String get backendOrigin {
      if (_backendOriginOverride.isNotEmpty) {
        return _normalizeOrigin(_backendOriginOverride);
      }

      if (kIsWeb) {
        return _normalizeOrigin(defaultBackendOrigin);
      }

      // Android emulator reaches host machine via 10.0.2.2
      if (Platform.isAndroid && useAndroidEmulator) {
        return 'http://10.0.2.2:$_defaultPort';
      }

      // Real phone / other platforms
      return _normalizeOrigin(defaultBackendOrigin);
    }

    static String get mlOrigin {
      if (_mlOriginOverride.isNotEmpty) return _mlOriginOverride;
      return defaultMlOrigin;
    }

    static String get apiV1Base => '$backendOrigin/api/v1';

    static String apiV1(String path) {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      return '$apiV1Base/$cleanPath';
    }

    static String mlUrl(String path) {
      final cleanPath = path.startsWith('/') ? path.substring(1) : path;
      return '$mlOrigin/$cleanPath';
    }

    static String get authBase => apiV1('auth');
    static String get chatBase => apiV1('chat');
    static String get aiChatbotBase => apiV1('aichatbot');
    static String get homeGardening => apiV1('homegarden');
    /// Fertilizer + pesticide advisory (POST body to this URL — no extra path segment).
    static String get advisoryBase => apiV1('advisory');

    /// Harvest timing advisory (POST body to this URL).
    static String get harvestBase => apiV1('harvest');

    /// Socket.IO server root URL (no /api/v1 prefix)
    static String get socketBase => backendOrigin;
  }
