import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_operation.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../views/authentication/screens/login_screen.dart';
import '../../views/authentication/screens/sign_up_screen.dart';
import '../../views/common/screens/splashscreen.dart';
import '../../views/homecreen/main_screen.dart';
import 'navigation_arguments.dart';

class NavigationController {
  static NavigationController? _instance;
  static String chatRoomId = "";
  static bool isNoInternetScreenShown = false;
  static bool isFirst = true;

  factory NavigationController() {
    _instance ??= NavigationController._();
    return _instance!;
  }

  NavigationController._();

  static final GlobalKey<NavigatorState> mainScreenNavigator = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> doctorScreenNavigator = GlobalKey<NavigatorState>();

  static bool isUserProfileTabInitialized = false;

  static bool checkDataAndNavigateToSplashScreen() {
    MyPrint.printOnConsole("checkDataAndNavigateToSplashScreen called, isFirst:$isFirst");

    if (isFirst) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        isFirst = false;
        Navigator.pushNamedAndRemoveUntil(mainScreenNavigator.currentContext!, SplashScreen.routeName, (route) => false);
      });
    }

    return isFirst;
  }

  static Route? onMainAppGeneratedRoutes(RouteSettings settings) {
    MyPrint.printOnConsole("onAdminMainGeneratedRoutes called for ${settings.name} with arguments:${settings.arguments}");

    if (kIsWeb) {
      if (!["/", SplashScreen.routeName].contains(settings.name) && NavigationController.checkDataAndNavigateToSplashScreen()) {
        return null;
      }
    }

    MyPrint.printOnConsole("First Page:$isFirst");
    Widget? page;

    switch (settings.name) {
      case "/":
        {
          page = const SplashScreen();
          break;
        }
      case LoginScreen.routeName:
        {
          page = parseLoginScreen(settings: settings);
          break;
        }
      case SignUpScreen.routeName:
        {
          page = parseSignUpScreen(settings: settings);
          break;
        }
      case MainScreen.routeName:
        {
          page = parseMainScreen(settings: settings);
          break;
        }
      // case MainScreen.routeName:
      //   {
      //     page = parseMainScreen(settings: settings);
      //     break;
      //   }
    }

    if (page != null) {
      return PageRouteBuilder(
        pageBuilder: (c, a1, a2) => page!,
        //transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
        transitionsBuilder: (c, anim, a2, child) => SizeTransition(sizeFactor: anim, child: child),
        transitionDuration: const Duration(milliseconds: 0),
        settings: settings,
      );
    }
    return null;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------------------------------

  //region Parse Page From RouteSettings

  static Widget? parseLoginScreen({required RouteSettings settings}) {
    return const LoginScreen();
  }

  static Widget? parseSignUpScreen({required RouteSettings settings}) {
    //
    return const SignUpScreen();
  }

  static Widget? parseMainScreen({required RouteSettings settings}) {
    return const MainScreen();
  }


  //endregion

  //------------------------------------------------------------------------------------------------------------------------------------------------------------
  static Future<dynamic> navigateToSignUpScreen({required NavigationOperationParameters navigationOperationParameters, required SignUpScreenNavigationArguments arguments}) {
    return NavigationOperation.navigate(
      navigationOperationParameters: navigationOperationParameters.copyWith(routeName: SignUpScreen.routeName, arguments: arguments),
    );
  }

  static Future<dynamic> navigateToLoginScreen({required NavigationOperationParameters navigationOperationParameters}) {
    return NavigationOperation.navigate(navigationOperationParameters: navigationOperationParameters.copyWith(routeName: LoginScreen.routeName));
  }

  static Future<dynamic> navigateToMainScreen({required NavigationOperationParameters navigationOperationParameters}) async {
    await SharedPrefManager().setBool(MySharedPreferenceVariables.isCreatorMode, false);
    return NavigationOperation.navigate(navigationOperationParameters: navigationOperationParameters.copyWith(routeName: MainScreen.routeName));
  }
}
