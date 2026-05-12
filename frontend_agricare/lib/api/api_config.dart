import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Single place to set your backend URL for a REAL PHONE.
  /// Make sure to include scheme and port.
  /// Example: 'http://192.168.100.9:5000'
  static const String defaultBackendOrigin = 'http://192.168.100.9:5000';

  /// Set to `true` only when running on Android Emulator.
  /// (Android emulator reaches your PC via 10.0.2.2)
  static const bool useAndroidEmulator = false;

  /// Override at runtime, e.g.
  /// `flutter run --dart-define=BACKEND_ORIGIN=http://192.168.1.10:5000`
  static const String _backendOriginOverride = String.fromEnvironment(
    'BACKEND_ORIGIN',
  );

  static const int _defaultPort = 5000;

  static String get backendOrigin {
    if (_backendOriginOverride.isNotEmpty) return _backendOriginOverride;

    if (kIsWeb) {
      return 'http://localhost:$_defaultPort';
    }

    // Android emulator reaches host machine via 10.0.2.2
    if (Platform.isAndroid && useAndroidEmulator) {
      return 'http://10.0.2.2:$_defaultPort';
    }

    // Real phone / other platforms
    return defaultBackendOrigin;
  }

  static String get apiV1Base => '$backendOrigin/api/v1';

  static String apiV1(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$apiV1Base/$cleanPath';
  }

  static String get authBase => apiV1('auth');
  static String get chatBase => apiV1('chat');
  static String get aiChatbotBase => apiV1('aichatbot');
  static String get homeGardening => apiV1('homegarden');
  static String get fertilizerHarvestAdvisory => apiV1('fertilizer');

  /// Socket.IO server root URL (no /api/v1 prefix)
  static String get socketBase => backendOrigin;
}
