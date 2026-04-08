import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'navigation_arguments.dart';
import 'routes.dart';

// Screens are imported from pages/ - these imports resolve once files are migrated
// from views/ to pages/
import '../pages/authentication/duress_pin_entry_screen.dart';
import '../pages/authentication/login_screen.dart';
import '../pages/authentication/pin_entry_screen.dart';
import '../pages/authentication/sign_up_screen.dart';
import '../pages/calls/voice_call_demo_screen.dart';
import '../pages/main_screen.dart';
import '../pages/splash_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signUp',
        name: Routes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/main',
        name: Routes.main,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/pinEntry',
        name: Routes.pinEntry,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return PinEntryScreen(
            arguments: args?['arguments'] as PinEntryScreenNavigationArguments?,
          );
        },
      ),
      GoRoute(
        path: '/duressPinEntry',
        name: Routes.duressPinEntry,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return DuressPinEntryScreen(
            arguments: args?['arguments'] as PinEntryScreenNavigationArguments?,
          );
        },
      ),
      GoRoute(
        path: '/voiceCall',
        name: Routes.voiceCall,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return VoiceCallScreen(
            arguments: args?['arguments'] as VoiceCallScreenNavigationArguments?,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri}')),
    ),
  );
}
