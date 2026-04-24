import 'package:frontend_agricare/screens/community_chat/create_group.dart';
import 'package:frontend_agricare/screens/community_chat/discover_group.dart';
import 'package:frontend_agricare/screens/community_chat/group_chat.dart';
import 'package:frontend_agricare/screens/marketplace/marketplace_register_screen.dart';
import 'package:get/get.dart';
import '../screens/splash_screen.dart';
import '../screens/auth_pages/login.dart';
import '../screens/auth_pages/signup.dart';
import '../screens/dashboard/dashboard.dart';
import '../screens/crop_recommendation/crop_recommendation_screen.dart';
import '../screens/ai_chatbot/ai_chat_page.dart';
import '../screens/community_chat/chat_dashboard.dart';
import '../screens/testscreen.dart';
import '../middleware/auth_middleware.dart';
import '../screens/marketplace/marketplace_screen.dart';
class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String recommendations = '/recommendations';
  static const String chatbot = '/chatbot';
  static const String community = '/community';
  static const String profile = '/profile';
  static const String marketplace = '/marketplace';   // 🔥 ADDED
  static const String marketplace_register_screen = '/marketplace-register';  
  static const String createGroup = '/create-group';
  static const String discoverGroups = '/discover-groups';
  static const String groupChat = '/group-chat';  



  // All routes
  static final routes = [
    // Public routes (no auth required)
    GetPage(name: splash, page: () => SplashScreen()),
    GetPage(name: login, page: () => LoginScreen()),
    GetPage(name: signup, page: () => SignupScreen()),
    GetPage(name: profile, page: () => ProfileScreen()),

    // Protected routes (auth required)
    GetPage(
      name: dashboard,
      page: () => DashboardScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: recommendations,
      page: () => CropRecommendationScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: chatbot,
      page: () => AIChatScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: community,
      page: () => ChatDashboard(),
      middlewares: [AuthMiddleware()],
    ),

    // 🔥 Marketplace route (protected)
    GetPage(
      name: marketplace,
      page: () => MarketplaceScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: marketplace_register_screen,
      page: () => MarketplaceRegisterScreen(),
      middlewares: [AuthMiddleware()],
    ),
     GetPage(
      name: groupChat,
      page: () => GroupChatScreen(),
      middlewares: [AuthMiddleware()],
    ),
     GetPage(
      name: discoverGroups,
      page: () => DiscoverGroupsScreen(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: createGroup,
      page: () => CreateGroupScreen(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
