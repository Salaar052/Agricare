import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/main_nav_controller.dart';
import '../routes/app_routes.dart';

import 'dashboard/dashboard.dart';
import 'marketplace/marketplace_screen.dart';
import 'marketplace/marketplace_register_screen.dart';
import 'crop_recommendation/crop_recommendation_screen.dart';
import 'crop_recommendation/weather_based_crop_screen.dart';
import 'community_chat/chat_dashboard.dart';
import 'community_chat/create_group.dart';
import 'community_chat/discover_group.dart';
import 'community_chat/group_chat.dart';
import 'testscreen.dart';

import 'ai_chatbot/ai_chat_page.dart';
import 'garden_recommendations/input_screen.dart' as garden;
import 'fertilizer_harvest_advisery/input_data_screen.dart' as fert;

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialInnerRoute;
  final Object? initialInnerArguments;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialInnerRoute,
    this.initialInnerArguments,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final MainNavController nav;

  @override
  void initState() {
    super.initState();

    nav = Get.isRegistered<MainNavController>()
        ? Get.find<MainNavController>()
        : Get.put(MainNavController(), permanent: true);
    nav.switchTab(widget.initialIndex);

    final inner = widget.initialInnerRoute;
    if (inner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Avoid pushing a duplicate if the request is for a tab root.
        if (nav.tabRootRoutes.contains(inner)) return;
        nav.navigate(inner, arguments: widget.initialInnerArguments);
      });
    }
  }

  Route<dynamic> _routeForDashboard(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DashboardScreen(),
        );
      case AppRoutes.chatbot:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AIChatScreen(),
        );
      case AppRoutes.gardenRecommendations:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => garden.InputScreen(),
        );
      case AppRoutes.fertilizerHarvestAdvisory:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => fert.FertilizerHarvestAdvisoryInputScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DashboardScreen(),
        );
    }
  }

  Route<dynamic> _routeForMarketplace(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.marketplace:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MarketplaceScreen(),
        );
      case AppRoutes.marketplace_register_screen:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MarketplaceRegisterScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MarketplaceScreen(),
        );
    }
  }

  Route<dynamic> _routeForCrops(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.recommendations:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CropRecommendationScreen(),
        );
      case AppRoutes.weatherBasedCrop:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WeatherBasedCropRecommendationScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CropRecommendationScreen(),
        );
    }
  }

  Route<dynamic> _routeForCommunity(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.community:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChatDashboard(),
        );
      case AppRoutes.discoverGroups:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DiscoverGroupsScreen(),
        );
      case AppRoutes.createGroup:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateGroupScreen(),
        );
      case AppRoutes.groupChat:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GroupChatScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChatDashboard(),
        );
    }
  }

  Route<dynamic> _routeForProfile(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProfileScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProfileScreen(),
        );
    }
  }

  Widget _buildTabNavigator({
    required GlobalKey<NavigatorState> key,
    required String initialRoute,
    required Route<dynamic> Function(RouteSettings) onGenerateRoute,
  }) {
    return Navigator(
      key: key,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) => onGenerateRoute(settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: nav.onWillPop,
      child: Obx(() {
        final index = nav.currentIndex.value;

        return Scaffold(
          body: IndexedStack(
            index: index,
            children: [
              _buildTabNavigator(
                key: nav.navigatorKeys[0],
                initialRoute: AppRoutes.dashboard,
                onGenerateRoute: _routeForDashboard,
              ),
              _buildTabNavigator(
                key: nav.navigatorKeys[1],
                initialRoute: AppRoutes.marketplace,
                onGenerateRoute: _routeForMarketplace,
              ),
              _buildTabNavigator(
                key: nav.navigatorKeys[2],
                initialRoute: AppRoutes.recommendations,
                onGenerateRoute: _routeForCrops,
              ),
              _buildTabNavigator(
                key: nav.navigatorKeys[3],
                initialRoute: AppRoutes.community,
                onGenerateRoute: _routeForCommunity,
              ),
              _buildTabNavigator(
                key: nav.navigatorKeys[4],
                initialRoute: AppRoutes.profile,
                onGenerateRoute: _routeForProfile,
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: index,
                onTap: (i) {
                  if (i == index) {
                    nav.popToTabRoot(i);
                  } else {
                    nav.switchTab(i);
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF4A7C2C),
                unselectedItemColor: const Color(0xFFB0BAB0),
                selectedFontSize: 11.5,
                unselectedFontSize: 11.5,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_rounded),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.storefront_rounded),
                    label: 'Market',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.agriculture_rounded),
                    label: 'Crops',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.forum_rounded),
                    label: 'Community',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

@Deprecated('Use MainNavigationScreen')
class MainShellScreen extends MainNavigationScreen {
  const MainShellScreen({
    super.key,
    super.initialIndex = 0,
    super.initialInnerRoute,
    super.initialInnerArguments,
  });
}
