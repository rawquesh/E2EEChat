import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../configs/constants.dart';
import '../views/authentication/screens/pin_entry_screen.dart';
import 'authentication/authentication_controller.dart';
import 'authentication/authentication_provider.dart';
import 'common/app_controller.dart';
import 'common/app_theme/app_theme_controller.dart';
import 'common/app_theme/app_theme_provider.dart';
import 'common/dependency_injection.dart';
import 'navigation/navigation_arguments.dart';
import 'navigation/navigation_controller.dart';
import 'notification/notification_service.dart';

class AppInitController {
  static bool isNavigateToObBoardingScreen = false;
  static bool isNavigateToSubSite = false;

  Future<bool> checkNavigateToOnBoardingScreen() async {
    String tag = MyUtils.getNewId();
    MyPrint.printOnConsole("AppInitController().checkNavigateToOnBoardingScreen() called", tag: tag);

    isNavigateToObBoardingScreen = false;

    bool? isFirst = await SharedPrefManager().getBool(MySharedPreferenceVariables.isFirst);
    MyPrint.printOnConsole("isFirst:$isFirst", tag: tag);
    if (isFirst != false) {
      SharedPrefManager().setBool(MySharedPreferenceVariables.isFirst, false);
      SharedPrefManager().setInt(MySharedPreferenceVariables.lastOpenedTime, DateTime.now().millisecondsSinceEpoch);

      isNavigateToObBoardingScreen = true;
    }

    MyPrint.printOnConsole("Final isNavigateToObBoardingScreen:$isNavigateToObBoardingScreen", tag: tag);

    return isNavigateToObBoardingScreen;
  }

  Future<void> initApp({required String appFlavor}) async {
    String tag = MyUtils.getNewId();
    MyPrint.printOnConsole("AppInitController().initApp() called", tag: tag);

    AppController.flavor = appFlavor;
    AppController.appType = AppTypes.user;

    List<Future> futures = [];

    // Simplified to only set orientation
    futures.add(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]),
    );

    AppThemeProvider themeProvider = DependencyInjection.appThemeProvider;
    AppThemeController themeController =
    AppThemeController(appThemeProvider: themeProvider);
    futures.add(themeController.init());
    futures.add(NotificationService().init());

    await Future.wait(futures);

    MyPrint.printOnConsole('Running $appFlavor version...');
    MyPrint.printOnConsole("AppInitController().initApp() Completed", tag: tag);
  }

  Future<void> getAllAppData({required BuildContext context, bool isNavigatedToOnBoardingScreen = false}) async {
    String tag = MyUtils.getNewId();
    MyPrint.printOnConsole("AppInitController().getAllAppData() called", tag: tag);

    await Future.wait([
      loadAssetImages(context: context),
    ]);

    MyPrint.printOnConsole("All Data Getting Completed", tag: tag);
  }

  Future<void> performInitialAppOpeningOperations({
    required BuildContext context,
    bool isNavigatedToOnBoardingScreen = false,
  }) async {
    String tag = MyUtils.getNewId();
    MyPrint.printOnConsole("AppInitController().performInitialAppOpeningOperations() called", tag: tag);

    if (isNavigatedToOnBoardingScreen) {
      return;
    }

    AuthenticationProvider authenticationProvider = DependencyInjection.authenticationProvider;
    AuthenticationController authenticationController = AuthenticationController(
      authenticationProvider: authenticationProvider,
    );

    // 1. Check for stored auth token
    String? authToken = await SharedPrefManager().getString(MySharedPreferenceVariables.authToken);
    MyPrint.printOnConsole("Stored authToken: ${authToken != null && authToken.isNotEmpty}", tag: tag);

    // 2. If no token, go to login/signup
    if (authToken == null || authToken.isEmpty) {
      MyPrint.printOnConsole("No token found, navigating to Login", tag: tag);
      NavigationController.navigateToLoginScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: context,
          navigationType: NavigationType.pushNamedAndRemoveUntil,
        ),
      );
      return;
    }

    // 3. If PIN is set, require PIN/biometric unlock
    bool hasPin = await authenticationController.hasPin();
    MyPrint.printOnConsole("User has pin: $hasPin", tag: tag);

    if (hasPin) {
      MyPrint.printOnConsole("Navigating to PIN entry screen", tag: tag);
      await NavigationController.navigateToPinEntryScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: context,
          navigationType: NavigationType.pushNamedAndRemoveUntil,
        ),
        arguments: PinEntryScreenNavigationArguments(
          mode: PinScreenMode.verify,
        ),
      );
      return;
    }

    // 4. If no PIN, force user to set a new PIN
    MyPrint.printOnConsole("PIN not set, navigating to set PIN", tag: tag);
    await NavigationController.navigateToPinEntryScreen(
      navigationOperationParameters: NavigationOperationParameters(
        context: context,
        navigationType: NavigationType.pushNamedAndRemoveUntil,
      ),
      arguments: PinEntryScreenNavigationArguments(
        mode: PinScreenMode.set,
      ),
    );
    return;

    // (Optional) After PIN/biometric unlock, you may want to check/refresh token validity:
    // - If token is expired, call AuthenticationController.refreshToken().
    // - If refresh fails, log out user and show login screen.
    // - If refresh succeeds or token is valid, proceed to main screen.

    // Example code for after unlock (you would put this in the PIN screen's success logic):
    /*
  bool isUserLoggedIn = await authenticationController.isUserLoggedIn();
  if (!isUserLoggedIn) {
    // Token expired/not valid, go to login
    NavigationController.navigateToLoginScreen(
      navigationOperationParameters: NavigationOperationParameters(
        context: context,
        navigationType: NavigationType.pushNamedAndRemoveUntil,
      ),
    );
    return;
  }

  // User is authenticated, go to main screen
  await NavigationController.navigateToMainScreen(
    navigationOperationParameters: NavigationOperationParameters(
      context: context,
      navigationType: NavigationType.pushNamedAndRemoveUntil,
    ),
  );
  */
  }


  Future<void> loadAssetImages({required BuildContext context}) async {
    String tag = MyUtils.getNewId();
    MyPrint.printOnConsole("AppInitController().loadAssetImages() called", tag: tag);

    List<String> assetImagesToPreCache = <String>[
      AppAssets.onBoardingSubImage1,
      AppAssets.onBoardingSubImage2,
      AppAssets.onBoardingSubImage3,
      AppAssets.onBoardingNextButton,
      AppAssets.kehilah_logo,
    ];
    MyPrint.printOnConsole("assetImagesToPreCache:$assetImagesToPreCache", tag: tag);

    await Future.wait(assetImagesToPreCache.map((element) => precacheImage(AssetImage(element), context)));

    MyPrint.printOnConsole("AppInitController().loadAssetImages() Completed", tag: tag);
  }
}