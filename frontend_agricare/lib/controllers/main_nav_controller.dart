import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';

class MainNavController extends GetxController {
  static const int tabCount = 5;

  /// 0: Dashboard, 1: Market, 2: Crops, 3: Community, 4: Profile
  final RxInt currentIndex = 0.obs;

  final List<GlobalKey<NavigatorState>> navigatorKeys =
      List.generate(tabCount, (_) => GlobalKey<NavigatorState>());

  final List<String> tabRootRoutes = const [
    AppRoutes.dashboard,
    AppRoutes.marketplace,
    AppRoutes.recommendations,
    AppRoutes.community,
    AppRoutes.profile,
  ];

  late final Map<String, int> routeToTabIndex = {
    // Tab roots
    AppRoutes.dashboard: 0,
    AppRoutes.marketplace: 1,
    AppRoutes.recommendations: 2,
    AppRoutes.community: 3,
    AppRoutes.profile: 4,

    // Dashboard-inner
    AppRoutes.chatbot: 0,
    AppRoutes.gardenRecommendations: 0,
    AppRoutes.fertilizerHarvestAdvisory: 0,

    // Marketplace-inner
    AppRoutes.marketplace_register_screen: 1,

    // Crops-inner
    AppRoutes.weatherBasedCrop: 2,

    // Community-inner
    AppRoutes.discoverGroups: 3,
    AppRoutes.createGroup: 3,
    AppRoutes.groupChat: 3,
    AppRoutes.groupDetail: 3,
  };

  void switchTab(int index) {
    if (index < 0 || index >= tabCount) return;
    currentIndex.value = index;
  }

  void popToTabRoot(int index) {
    if (index < 0 || index >= tabCount) return;
    navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
  }

  /// Switches to the Dashboard tab and ensures its nested navigator
  /// is popped to the tab root.
  void goToDashboardRoot() {
    popToTabRoot(0);
    switchTab(0);
  }

  void navigate(String routeName, {Object? arguments}) {
    final targetTab = routeToTabIndex[routeName];
    if (targetTab != null) {
      final wasSameTab = targetTab == currentIndex.value;
      switchTab(targetTab);

      // If it's a tab root route, don't push another copy; just pop to root.
      if (tabRootRoutes.contains(routeName)) {
        if (wasSameTab) {
          popToTabRoot(targetTab);
        }
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKeys[targetTab].currentState
            ?.pushNamed(routeName, arguments: arguments);
      });
      return;
    }

    // Unknown route: push into current tab navigator.
    final idx = currentIndex.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKeys[idx].currentState?.pushNamed(routeName, arguments: arguments);
    });
  }

  Future<bool> onWillPop() async {
    final idx = currentIndex.value;
    final nav = navigatorKeys[idx].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }

    if (idx != 0) {
      switchTab(0);
      return false;
    }

    return true;
  }
}
