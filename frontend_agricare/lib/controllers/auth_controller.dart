// ============================================
// AUTH CONTROLLER
// lib/controllers/auth_controller.dart
// ============================================

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final storage = GetStorage();

  static const String _locationPrefsPrefix = 'location_prefs_';

  // ── Reactive variables ─────────────────────────────────────────────────────
  var userId = "".obs;
  var username = "".obs;
  var email = "".obs;
  var profileImage = "".obs;
  var token = "".obs;
  var isAdmin = false.obs;
  var isEmailVerified = false.obs;
  var isLoggedIn = false.obs;
  var isLoading = false.obs;

  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var temperature = 0.0.obs;
  var locationLabel = ''.obs;
  var locationSetupCompleted = false.obs;

  String? _normalizedEmailForPrefs([String? raw]) {
    final v = (raw ?? email.value).trim().toLowerCase();
    if (v.isEmpty) return null;
    return v;
  }

  String? _locationPrefsKeyForCurrentUser() {
    final e = _normalizedEmailForPrefs();
    if (e == null) return null;
    return '$_locationPrefsPrefix$e';
  }

  void _persistLocationPrefs({bool? setupCompleted}) {
    final key = _locationPrefsKeyForCurrentUser();
    if (key == null) return;

    final existing = storage.read(key) as Map? ?? {};
    final payload = <String, dynamic>{
      ...existing,
      'lat': latitude.value,
      'lng': longitude.value,
      'temp': temperature.value,
      'locationLabel': locationLabel.value,
      if (setupCompleted != null)
        'locationSetupCompleted': setupCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    storage.write(key, payload);
  }

  void _restoreLocationPrefsForEmail(String emailValue) {
    final e = _normalizedEmailForPrefs(emailValue);
    if (e == null) return;

    final key = '$_locationPrefsPrefix$e';
    final prefs = storage.read(key);
    if (prefs is! Map) return;

    final prefLat = (prefs['lat'] as num?)?.toDouble();
    final prefLng = (prefs['lng'] as num?)?.toDouble();
    final prefTemp = (prefs['temp'] as num?)?.toDouble();
    final prefLabel = (prefs['locationLabel'] as String?) ?? '';
    final prefSetup = prefs['locationSetupCompleted'] == true;

    if (prefLat != null) latitude.value = prefLat;
    if (prefLng != null) longitude.value = prefLng;
    if (prefTemp != null) temperature.value = prefTemp;
    if (prefLabel.isNotEmpty) locationLabel.value = prefLabel;
    if (prefSetup) locationSetupCompleted.value = true;

    // Keep the primary user blob in sync (used by other screens).
    final savedUser = storage.read('user') as Map? ?? {};
    if (prefLat != null) savedUser['lat'] = prefLat;
    if (prefLng != null) savedUser['lng'] = prefLng;
    if (prefTemp != null) savedUser['temp'] = prefTemp;
    if (prefLabel.isNotEmpty) savedUser['locationLabel'] = prefLabel;
    if (prefSetup) savedUser['locationSetupCompleted'] = true;
    storage.write('user', savedUser);
  }

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  // ── setLocation: persist lat/lng/temp ─────────────────────────────────────
  void setLocation({
    required double lat,
    required double lng,
    double? temp,
    String? label,
  }) {
    latitude.value = lat;
    longitude.value = lng;

    if (temp != null) {
      temperature.value = temp;
    }

    if (label != null) {
      locationLabel.value = label;
    }

    final savedUser = storage.read("user") as Map? ?? {};
    savedUser["lat"] = lat;
    savedUser["lng"] = lng;
    if (temp != null) savedUser["temp"] = temp;
    if (label != null) savedUser["locationLabel"] = label;

    // If the user has explicitly selected a location, treat setup as completed.
    if ((lat != 0.0 || lng != 0.0) && locationSetupCompleted.value != true) {
      locationSetupCompleted.value = true;
      savedUser['locationSetupCompleted'] = true;
    }

    storage.write("user", savedUser);

    // Persist for future logins even if the user logs out.
    _persistLocationPrefs(
      setupCompleted: savedUser['locationSetupCompleted'] == true,
    );
  }

  void setLocationSetupCompleted(bool completed) {
    locationSetupCompleted.value = completed;
    final savedUser = storage.read('user') as Map? ?? {};
    savedUser['locationSetupCompleted'] = completed;
    storage.write('user', savedUser);

    _persistLocationPrefs(setupCompleted: completed);
  }

  bool get needsLocationSetup => locationSetupCompleted.value != true;

  // ── setUser: called after successful login ─────────────────────────────────
  // Triggers a background location fetch so the dashboard already has coords.
  void setUser(Map<String, dynamic> data) {
    try {
      userId.value = data["_id"] ?? "";
      username.value = data["username"] ?? "";
      email.value = data["email"] ?? "";
      profileImage.value = data["profileImage"] ?? "";
      token.value = data["token"] ?? "";
      isAdmin.value = data["isAdmin"] ?? false;
      isEmailVerified.value = data["isEmailVerified"] ?? false;
      isLoggedIn.value = true;

      // IMPORTANT: preserve existing stored fields like lat/lng/temp and flags.
      final existing = storage.read('user') as Map? ?? {};
      storage.write('user', {
        ...existing,
        "_id": userId.value,
        "username": username.value,
        "email": email.value,
        "profileImage": profileImage.value,
        "token": token.value,
        "isAdmin": isAdmin.value,
        "isEmailVerified": isEmailVerified.value,
        "isLoggedIn": true,
      });

      print('✅ User data saved successfully');

      // Restore previously saved location preferences for this account.
      // This prevents re-prompting for location on every new login.
      if (email.value.isNotEmpty) {
        _restoreLocationPrefsForEmail(email.value);
      }
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  // ── loadUser: restore from GetStorage ─────────────────────────────────────
  void loadUser() {
    try {
      final savedUser = storage.read("user");
      if (savedUser != null) {
        userId.value = savedUser["_id"] ?? "";
        username.value = savedUser["username"] ?? "";
        email.value = savedUser["email"] ?? "";
        profileImage.value = savedUser["profileImage"] ?? "";
        token.value = savedUser["token"] ?? "";
        isAdmin.value = savedUser["isAdmin"] ?? false;
        isEmailVerified.value = savedUser["isEmailVerified"] ?? false;
        isLoggedIn.value = savedUser["isLoggedIn"] ?? false;

        // Restore previously saved coordinates
        latitude.value = (savedUser["lat"] as num?)?.toDouble() ?? 0.0;
        longitude.value = (savedUser["lng"] as num?)?.toDouble() ?? 0.0;
        temperature.value = (savedUser["temp"] as num?)?.toDouble() ?? 0.0;
        locationLabel.value = (savedUser['locationLabel'] as String?) ?? '';
        locationSetupCompleted.value = savedUser['locationSetupCompleted'] == true;

        // Also restore persisted location prefs (survives logout/login).
        if (email.value.isNotEmpty) {
          _restoreLocationPrefsForEmail(email.value);
        }

        print('✅ User data loaded from storage');
        print('👤 Username: ${username.value}');
        print('📧 Email: ${email.value}');
        print(
          '📍 Coords: ${latitude.value}, ${longitude.value} | ${temperature.value}°C',
        );
      } else {
        print('⚠️ No saved user data found');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // ── updateProfileImage ─────────────────────────────────────────────────────
  void updateProfileImage(String newImageUrl) {
    try {
      profileImage.value = newImageUrl;
      final savedUser = storage.read("user");
      if (savedUser != null) {
        savedUser["profileImage"] = newImageUrl;
        storage.write("user", savedUser);
        print('✅ Profile image updated in storage');
      }
    } catch (e) {
      print('❌ Error updating profile image: $e');
    }
  }

  // ── updateProfileInfo ──────────────────────────────────────────────────────
  void updateProfileInfo({
    required String newUsername,
    required String newEmail,
  }) {
    try {
      username.value = newUsername;
      email.value = newEmail;
      final savedUser = storage.read("user");
      if (savedUser != null) {
        savedUser["username"] = newUsername;
        savedUser["email"] = newEmail;
        storage.write("user", savedUser);
      }
    } catch (e) {
      print('❌ Error updating profile info: $e');
    }
  }

  // ── logout ─────────────────────────────────────────────────────────────────
  void logout() {
    try {
      userId.value = "";
      username.value = "";
      email.value = "";
      profileImage.value = "";
      token.value = "";
      isAdmin.value = false;
      isEmailVerified.value = false;
      isLoggedIn.value = false;
      latitude.value = 0.0;
      longitude.value = 0.0;
      temperature.value = 0.0;
      locationLabel.value = '';
      locationSetupCompleted.value = false;
      storage.remove("user");
      print('✅ User logged out and data cleared');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  Future<void> clearAllLocalData() async {
    // Clears *everything* stored locally, including persisted location prefs.
    try {
      await storage.erase();
    } catch (_) {
      // ignore
    } finally {
      logout();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.value}',
    };
  }

  bool get hasProfileImage => profileImage.value.isNotEmpty;

  bool get hasLocation => latitude.value != 0.0 || longitude.value != 0.0;
}
