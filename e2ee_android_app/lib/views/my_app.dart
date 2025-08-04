import 'package:e2ee_android_app/backend/authentication/authentication_provider.dart';
import 'package:e2ee_android_app/backend/webrtc/call_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

import '../backend/app_init_controller.dart';
import '../backend/chats/chats_provider.dart';
import '../backend/common/app_state.dart';
import '../backend/common/app_theme/app_theme_provider.dart';
import '../backend/common/dependency_injection.dart';
import '../backend/navigation/navigation_controller.dart';
import 'common/components/my_scroll_behaviour.dart';
import 'common/screens/splashscreen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>.value(value: DependencyInjection.appThemeProvider),
        ChangeNotifierProvider<AuthenticationProvider>.value(value: DependencyInjection.authenticationProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: DependencyInjection.chatProvider),
        ChangeNotifierProvider<AppState>.value(value: DependencyInjection.appState),
        ChangeNotifierProvider<CallProvider>.value(value: DependencyInjection.callProvider),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final AppInitController _controller = AppInitController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.performInitialAppOpeningOperations(context: context, isNavigatedToOnBoardingScreen: AppInitController.isNavigateToObBoardingScreen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: Consumer<AppThemeProvider>(
        builder: (context, appThemeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: NavigationController.mainScreenNavigator,
            title: "DarkCrypt Chat",
            theme: appThemeProvider.getDarkThemeData(),
            initialRoute: AppInitController.isNavigateToObBoardingScreen ? SplashScreen.routeName : null,
            onGenerateRoute: NavigationController.onMainAppGeneratedRoutes,
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const MyScrollBehavior(),
                child: AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, child: child ?? const SizedBox()),
              );
            },
          );
        },
      ),
    );
  }
}
