import 'package:e2ee_android_app/backend/authentication/authentication_provider.dart';
import 'package:e2ee_android_app/backend/chats/chats_provider.dart';
import 'package:e2ee_android_app/backend/common/app_state.dart';
import 'package:e2ee_android_app/backend/common/dependency_injection.dart';
import 'package:e2ee_android_app/backend/webrtc/call_provider.dart';
import 'package:e2ee_android_app/navigation/app_router.dart';
import 'package:e2ee_android_app/styles/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

import '../backend/app_init_controller.dart';
import 'components/my_scroll_behaviour.dart';

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
      _controller.performInitialAppOpeningOperations(
        context: context,
        isNavigatedToOnBoardingScreen: AppInitController.isNavigateToObBoardingScreen,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: Consumer<AppThemeProvider>(
        builder: (context, appThemeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            title: "DarkCrypt Chat",
            theme: appThemeProvider.getThemeData(),
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const MyScrollBehavior(),
                child: AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle.dark,
                  child: child ?? const SizedBox(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
