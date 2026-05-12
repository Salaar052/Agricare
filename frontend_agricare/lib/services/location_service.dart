// ============================================================
// location_service.dart — GPS + Full Weather Fetching
// Works on Android, iOS, and Web (Flutter)
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationSearchResult {
  final String label;
  final double latitude;
  final double longitude;

  const LocationSearchResult({
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

/// Full weather snapshot returned from Open-Meteo
class WeatherData {
  final double temperature;
  final double humidity;
  final double windspeed;
  final String skyLabel;
  final int? weatherCode;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windspeed,
    required this.skyLabel,
    this.weatherCode,
  });

  /// Friendly fallback when location / network is unavailable
  factory WeatherData.fallback() => const WeatherData(
    temperature: 28.0,
    humidity: 65.0,
    windspeed: 12.0,
    skyLabel: 'Partly',
    weatherCode: null,
  );

  String get tempDisplay => '${temperature.round()}°C';
  String get humidityDisplay => '${humidity.round()}%';
  String get windDisplay => '${windspeed.round()} km/h';
}

class LocationService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ── Public: request permission + get position (mobile & web) ──────────────
  Future<Position?> getCurrentPosition() async {
    try {
      if (kIsWeb) {
        return await _getPositionWeb();
      } else {
        return await _getPositionMobile();
      }
    } catch (e) {
      print('❌ LocationService.getCurrentPosition error: $e');
      return null;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  // ── Mobile (Android / iOS) permission + position flow ─────────────────────
  Future<Position?> _getPositionMobile() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Location services disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ Location permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('⚠️ Location permission permanently denied');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  // ── Web permission + position flow ─────────────────────────────────────────
  // On web, geolocator delegates to the browser's navigator.geolocation API.
  // The browser will show its own native permission prompt automatically.
  Future<Position?> _getPositionWeb() async {
    // On web, checkPermission() may throw on some browsers — guard it.
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {
      permission = LocationPermission.denied;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (e) {
        print('⚠️ Web location permission request failed: $e');
        return null;
      }
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('⚠️ Web location permission denied');
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  // ── Public: fetch full weather from Open-Meteo (no API key needed) ─────────
  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current_weather=true'
        '&hourly=relativehumidity_2m,windspeed_10m'
        '&temperature_unit=celsius'
        '&windspeed_unit=kmh'
        '&timezone=auto'
        '&forecast_days=1',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final currentWeather = data['current_weather'] as Map<String, dynamic>?;
        final temp = (currentWeather?['temperature'] as num?)?.toDouble();
        final windspeed = (currentWeather?['windspeed'] as num?)?.toDouble();
        final weatherCode = currentWeather?['weathercode'] as int?;

        // Hourly arrays — index 0 is the first hour of today (close enough)
        final humidityList = (data['hourly']?['relativehumidity_2m'] as List?);
        final humidity =
            (humidityList?.isNotEmpty == true ? humidityList![0] as num? : null)
                ?.toDouble() ??
            65.0;

        if (temp != null) {
          return WeatherData(
            temperature: temp,
            humidity: humidity,
            windspeed: windspeed ?? 12.0,
            skyLabel: _codeToSkyLabel(weatherCode),
            weatherCode: weatherCode,
          );
        }
      }

      print('⚠️ Open-Meteo returned ${response.statusCode}');
      return WeatherData.fallback();
    } catch (e) {
      print('❌ LocationService.getWeather error: $e');
      return WeatherData.fallback();
    }
  }

  // ── Convenience: position + weather in one call ────────────────────────────
  /// Returns (position, weather). Position may be null if denied.
  Future<({Position? position, WeatherData weather})>
  getLocationAndWeather() async {
    final position = await getCurrentPosition();

    if (position == null) {
      return (position: null, weather: WeatherData.fallback());
    }

    final weather = await getWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return (position: position, weather: weather);
  }

  // ── Helper: raw HTTP GET (reusable by other classes) ──────────────────────
  Future<http.Response?> httpGet(Uri uri) async {
    try {
      return await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
  }

  /// Manual location search using Open-Meteo Geocoding (no API key).
  Future<List<LocationSearchResult>> searchLocations(String query, {int count = 6}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeComponent(q)}'
        '&count=$count'
        '&language=en&format=json',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      return results
          .map((r) => r as Map<String, dynamic>)
          .map((r) {
            final name = (r['name'] as String?)?.trim();
            final admin1 = (r['admin1'] as String?)?.trim();
            final country = (r['country'] as String?)?.trim();
            final lat = (r['latitude'] as num?)?.toDouble();
            final lng = (r['longitude'] as num?)?.toDouble();

            if (name == null || lat == null || lng == null) return null;

            final parts = <String>[name];
            if (admin1 != null && admin1.isNotEmpty) parts.add(admin1);
            if (country != null && country.isNotEmpty) parts.add(country);
            return LocationSearchResult(
              label: parts.join(', '),
              latitude: lat,
              longitude: lng,
            );
          })
          .whereType<LocationSearchResult>()
          .toList();
    } catch (e) {
      print('❌ LocationService.searchLocations error: $e');
      return [];
    }
  }

  /// Reverse geocode: lat/lng -> human label (free, no API key)
  Future<String> reverseGeocodeLabel(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client'
        '?latitude=$lat&longitude=$lng&localityLanguage=en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return 'Unknown';
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final city = (data['city'] as String?)?.trim();
      final locality = (data['locality'] as String?)?.trim();
      final subdivision = (data['principalSubdivision'] as String?)?.trim();
      final country = (data['countryName'] as String?)?.trim();

      return city?.isNotEmpty == true
          ? city!
          : locality?.isNotEmpty == true
              ? locality!
              : subdivision?.isNotEmpty == true
                  ? subdivision!
                  : country ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  // ── WMO weather code → short sky label ────────────────────────────────────
  String _codeToSkyLabel(int? code) {
    if (code == null) return 'Partly';
    if (code == 0) return 'Clear';
    if (code <= 2) return 'Partly';
    if (code == 3) return 'Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 69) return 'Rainy';
    if (code <= 79) return 'Snowy';
    if (code <= 99) return 'Stormy';
    return 'Partly';
  }

  // ── Fallback temperature only (legacy compat) ─────────────────────────────
  double getMockTemperature() => 28.0;

  /// Legacy: temperature-only fetch (kept for backward compatibility)
  Future<double> getTemperature({Position? position}) async {
    if (position == null) return getMockTemperature();
    final weather = await getWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    return weather.temperature;
  }
}
