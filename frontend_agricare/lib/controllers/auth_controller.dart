// ============================================
// 2. AUTH CONTROLLER (lib/controllers/auth_controller.dart)
// ============================================
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final storage = GetStorage();
  
  // Reactive variables
  var userId = "".obs;
  var username = "".obs;
  var email = "".obs;
  var profileImage = "".obs;
  var token = "".obs;
  var isLoggedIn = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  // Save user to store + persist
  void setUser(Map<String, dynamic> data) {
    try {
      userId.value = data["_id"] ?? "";
      username.value = data["username"] ?? "";
      email.value = data["email"] ?? "";
      profileImage.value = data["profileImage"] ?? "";
      token.value = data["token"] ?? "";
      isLoggedIn.value = true;

      // Save to GetStorage
      storage.write("user", {
        "_id": userId.value,
        "username": username.value,
        "email": email.value,
        "profileImage": profileImage.value,
        "token": token.value,
        "isLoggedIn": true,
      });

      print('✅ User data saved successfully');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }

  // Load user from persistence
  void loadUser() {
    try {
      final savedUser = storage.read("user");
      if (savedUser != null) {
        userId.value = savedUser["_id"] ?? "";
        username.value = savedUser["username"] ?? "";
        email.value = savedUser["email"] ?? "";
        profileImage.value = savedUser["profileImage"] ?? "";
        token.value = savedUser["token"] ?? "";
        isLoggedIn.value = savedUser["isLoggedIn"] ?? false;
        
        print('✅ User data loaded from storage');
        print('👤 Username: ${username.value}');
        print('📧 Email: ${email.value}');
      } else {
        print('⚠️ No saved user data found');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // Update profile image
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

  // Clear user on logout
  void logout() {
    try {
      userId.value = "";
      username.value = "";
      email.value = "";
      profileImage.value = "";
      token.value = "";
      isLoggedIn.value = false;
      storage.remove("user");
      
      print('✅ User logged out and data cleared');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  // Helper to get auth headers
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.value}',
    };
  }

  // Helper for profile image
  bool get hasProfileImage => profileImage.value.isNotEmpty;
}