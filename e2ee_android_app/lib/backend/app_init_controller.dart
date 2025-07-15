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
import 'authentication/authentication_controller.dart';
import 'authentication/authentication_provider.dart';
import 'common/app_controller.dart';
import 'common/app_theme/app_theme_controller.dart';
import 'common/app_theme/app_theme_provider.dart';
import 'common/dependency_injection.dart';
import 'navigation/navigation_controller.dart';

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

    String? userId = await SharedPrefManager().getString('user_id');
    String? authToken = await SharedPrefManager().getString('auth_token');

    MyPrint.printOnConsole("Stored credentials - userId: $userId, authToken: ${authToken != null && authToken.isNotEmpty}", tag: tag);

    bool isUserLoggedIn = await authenticationController.isUserLoggedIn();
    MyPrint.printOnConsole("isUserLoggedIn:$isUserLoggedIn", tag: tag);

    if (!isUserLoggedIn) {
      MyPrint.printOnConsole(
        "Returning from AppInitController().performInitialAppOpeningOperations() because Navigated to Login Screen",
        tag: tag,
      );

      NavigationController.navigateToLoginScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: context,
          navigationType: NavigationType.pushNamedAndRemoveUntil,
        ),
      );
      return;
    }


    // User is logged in, check if profile exists
    // bool isExist = await authenticationController.checkUserWithIdExistOrNotAndIfNotExistThenCreate(
    //   userId: authenticationProvider.userId.get(),
    // );

    UserModel? userModel = authenticationProvider.userModel.get();
    bool isCreatorMode =
        await SharedPrefManager().getBool(MySharedPreferenceVariables.isCreatorMode) ?? false;

    if (userModel != null) {
    // if (userModel != null && (userModel.firstName.isEmpty || userModel.isDeleted || !isExist)) {
      // User exists but needs to complete profile
      if (isCreatorMode && userModel.isCreator == true) {
        await NavigationController.navigateToMainScreen(
          navigationOperationParameters: NavigationOperationParameters(
            context: context,
            navigationType: NavigationType.pushNamedAndRemoveUntil,
          ),
        );
        return;
      } else {
        await NavigationController.navigateToMainScreen(
          navigationOperationParameters: NavigationOperationParameters(
            context: context,
            navigationType: NavigationType.pushNamedAndRemoveUntil,
          ),
        );
        return;
      }
    }

    // User is fully logged in with complete profile, navigate to main screen
    /*if (isCreatorMode && (userModel.isCreator == true)) {
      await NavigationController.navigateToCreatorMainScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: context,
          navigationType: NavigationType.pushNamedAndRemoveUntil,
        ),
      );
    } else {
      await NavigationController.navigateToMainScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: context,
          navigationType: NavigationType.pushNamedAndRemoveUntil,
        ),
      );
    }*/
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