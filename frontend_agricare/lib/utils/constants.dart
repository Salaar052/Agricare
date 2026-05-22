// ============================================================
// constants.dart — App-wide Constants
// ============================================================
import '../api/api_config.dart';

class AppConstants {
  // ── API ────────────────────────────────────────────────────
  // Replace with your actual backend URL
  static String get baseUrl => ApiConfig.homeGardening;
  static final String recommendEndpoint = '$baseUrl/recommend';

  // ── Timeouts ───────────────────────────────────────────────
  static const Duration apiTimeout = Duration(seconds: 30);

  // ── UI ────────────────────────────────────────────────────
  static const double cardRadius = 20.0;
  static const double pagePadding = 20.0;

  // ── Colors ────────────────────────────────────────────────
  // Defined in theme.dart

  // ── Options ───────────────────────────────────────────────
  static const List<Map<String, String>> spaceOptions = [
    {'value': 'balcony', 'label': 'Balcony', 'icon': '🏠'},
    {'value': 'garden', 'label': 'Garden', 'icon': '🌳'},
    {'value': 'indoor', 'label': 'Indoor', 'icon': '🪴'},
  ];

  static const List<Map<String, String>> sunlightOptions = [
    {'value': 'full', 'label': 'Full Sun', 'icon': '☀️'},
    {'value': 'partial', 'label': 'Partial Sun', 'icon': '⛅'},
    {'value': 'shade', 'label': 'Shade', 'icon': '🌥️'},
  ];

  static const List<Map<String, String>> waterOptions = [
    {'value': 'low', 'label': 'Low', 'icon': '💧'},
    {'value': 'medium', 'label': 'Medium', 'icon': '💧'},
    {'value': 'high', 'label': 'High', 'icon': '💧'},
  ];
}
