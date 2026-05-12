import 'package:frontend_agricare/screens/community_chat/create_group.dart';
import 'package:frontend_agricare/screens/community_chat/discover_group.dart';
import 'package:frontend_agricare/screens/community_chat/group_chat.dart';
import 'package:frontend_agricare/screens/marketplace/marketplace_register_screen.dart';
import 'package:get/get.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_pages/login.dart';
import '../screens/auth_pages/signup.dart';
import '../screens/auth_pages/verify_email.dart';
import '../screens/auth_pages/forgot_password.dart';
import '../screens/auth_pages/location_setup_screen.dart';
import '../screens/dashboard/dashboard.dart';
import '../screens/dashboard/admin_dashboard.dart';
import '../screens/dashboard/admin_profile_screen.dart';
import '../screens/crop_recommendation/crop_recommendation_screen.dart';
import '../screens/crop_recommendation/weather_based_crop_screen.dart';
import '../screens/ai_chatbot/ai_chat_page.dart';
import '../screens/community_chat/chat_dashboard.dart';
import '../screens/testscreen.dart';
import '../screens/main_shell_screen.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/admin_middleware.dart';
import '../screens/marketplace/marketplace_screen.dart';
import '../screens/garden_recommendations/input_screen.dart';
import '../screens/fertilizer_harvest_advisery/input_data_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String locationSetup = '/location-setup';
  static const String dashboard = '/dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminProfile = '/admin-profile';
  static const String recommendations = '/recommendations';
  static const String weatherBasedCrop = '/weather-based-crop';
  static const String chatbot = '/chatbot';
  static const String community = '/community';
  static const String profile = '/profile';
  static const String marketplace = '/marketplace'; // 🔥 ADDED
  static const String marketplace_register_screen = '/marketplace-register';
  static const String createGroup = '/create-group';
  static const String discoverGroups = '/discover-groups';
  static const String groupChat = '/group-chat';
  static const String gardenRecommendations = '/garden-recommendations';
  static const String fertilizerHarvestAdvisory =
      '/fertilizer-harvest-advisory';

  // All routes
  static final routes = [
    // Public routes (no auth required)
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: signup, page: () => SignupScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(
      name: locationSetup,
      page: () => const LocationSetupScreen(),
      middlewares: [AuthMiddleware()],
    ),

    // Shell routes (auth required)
    GetPage(
      name: dashboard,
      page: () => const MainNavigationScreen(initialIndex: 0),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: marketplace,
      page: () => const MainNavigationScreen(initialIndex: 1),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: recommendations,
      page: () => const MainNavigationScreen(initialIndex: 2),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: community,
      page: () => const MainNavigationScreen(initialIndex: 3),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: profile,
      page: () => const MainNavigationScreen(initialIndex: 4),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: adminDashboard,
      page: () => AdminDashboardScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: adminProfile,
      page: () => const AdminProfileScreen(),
      middlewares: [AdminMiddleware()],
    ),
    // Deep links into shell tabs (auth required)
    GetPage(
      name: weatherBasedCrop,
      page: () => const MainNavigationScreen(
        initialIndex: 2,
        initialInnerRoute: AppRoutes.weatherBasedCrop,
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: chatbot,
      page: () => const MainNavigationScreen(
        initialIndex: 0,
        initialInnerRoute: AppRoutes.chatbot,
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: marketplace_register_screen,
      page: () => const MainNavigationScreen(
        initialIndex: 1,
        initialInnerRoute: AppRoutes.marketplace_register_screen,
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: discoverGroups,
      page: () => const MainNavigationScreen(
        initialIndex: 3,
        initialInnerRoute: AppRoutes.discoverGroups,
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: createGroup,
      page: () => const MainNavigationScreen(
        initialIndex: 3,
        initialInnerRoute: AppRoutes.createGroup,
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: groupChat,
      page: () => MainNavigationScreen(
        initialIndex: 3,
        initialInnerRoute: AppRoutes.groupChat,
        initialInnerArguments: Get.arguments,
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: gardenRecommendations,
      page: () => const MainNavigationScreen(
        initialIndex: 0,
        initialInnerRoute: AppRoutes.gardenRecommendations,
      ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: fertilizerHarvestAdvisory,
      page: () => const MainNavigationScreen(
        initialIndex: 0,
        initialInnerRoute: AppRoutes.fertilizerHarvestAdvisory,
      ),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
