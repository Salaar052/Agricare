import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class AdminMiddleware extends GetMiddleware {
  final AuthController authController = Get.find<AuthController>();

  @override
  int? get priority => 0;

  @override
  RouteSettings? redirect(String? route) {
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (!authController.isAdmin.value) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }

    return null;
  }
}
