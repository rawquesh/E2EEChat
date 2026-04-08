import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../managers/shared_pref_manager.dart';
import 'app_router.dart';
import 'navigation_arguments.dart';
import 'routes.dart';

class DirectNavigator {
  DirectNavigator._();

  static BuildContext? get _context => AppRouter.rootNavigatorKey.currentContext;

  static void navigateToLogin() {
    _context?.goNamed(Routes.login);
  }

  static void navigateToPinEntry({required PinEntryScreenNavigationArguments arguments}) {
    _context?.goNamed(
      Routes.pinEntry,
      extra: {'arguments': arguments},
    );
  }

  static void navigateToDuressPinEntry({required PinEntryScreenNavigationArguments arguments}) {
    _context?.goNamed(
      Routes.duressPinEntry,
      extra: {'arguments': arguments},
    );
  }

  static void navigateToMain() {
    SharedPrefManager().setBool(MySharedPreferenceVariables.isCreatorMode, false);
    _context?.goNamed(Routes.main);
  }

  static void navigateToVoiceCall({required VoiceCallScreenNavigationArguments arguments}) {
    _context?.pushNamed(
      Routes.voiceCall,
      extra: {'arguments': arguments},
    );
  }

  static void navigateToSplash() {
    _context?.goNamed(Routes.splash);
  }

  static void navigateToSignUp({required SignUpScreenNavigationArguments arguments}) {
    _context?.goNamed(
      Routes.signUp,
      extra: {'arguments': arguments},
    );
  }
}
