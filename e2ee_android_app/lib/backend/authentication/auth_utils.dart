import 'package:e2ee_android_app/backend/authentication/authentication_controller.dart';
import 'package:e2ee_android_app/backend/common/dependency_injection.dart';
import 'package:e2ee_android_app/backend/navigation/navigation_controller.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/utils/my_toast.dart';
import 'package:flutter/material.dart';

class AuthUtils {
  static Future<void> handleUnauthorized({BuildContext? context, String? message}) async {
    final provider = DependencyInjection.authenticationProvider;
    final controller = AuthenticationController(authenticationProvider: provider);
    await controller.wipeAllAuthData();
    final ctx = context ?? NavigationController.mainScreenNavigator.currentContext;
    if (ctx != null) {
      MyToast.showError(
        context: ctx,
        msg: message ?? 'Session expired. Please log in again.',
      );
      await NavigationController.navigateToLoginScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: ctx,
          navigationType: NavigationType.pushNamedAndRemoveUntil,
        ),
      );
    }
  }
}
