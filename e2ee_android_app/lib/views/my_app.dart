import 'package:e2ee_android_app/backend/authentication/authentication_controller.dart';
import 'package:e2ee_android_app/backend/authentication/authentication_provider.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:responsive_builder/responsive_builder.dart';

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
    MyPrint.printOnConsole("MyApp Build Called");

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>.value(value: DependencyInjection.appThemeProvider),
        ChangeNotifierProvider<AuthenticationProvider>.value(value: DependencyInjection.authenticationProvider),
        ChangeNotifierProvider<ChatProvider>.value(value: DependencyInjection.chatProvider),
        ChangeNotifierProvider<AppState>.value(value: DependencyInjection.appState),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    MyPrint.printOnConsole("MainApp Build Called");

    return OverlaySupport.global(
      child: Consumer<AppThemeProvider>(
        builder: (BuildContext context, AppThemeProvider appThemeProvider, Widget? child) {
          return ResponsiveBuilder(
            builder: (context, sizingInformation) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: NavigationController.mainScreenNavigator,
                title: "DarkCrypt Chat",
                theme: appThemeProvider.getDarkThemeData(),
                initialRoute: AppInitController.isNavigateToObBoardingScreen ? SplashScreen.routeName : null,
                onGenerateRoute: NavigationController.onMainAppGeneratedRoutes,
                builder: (BuildContext context, Widget? child) {
                  return ScrollConfiguration(
                    behavior: const MyScrollBehavior(),
                    child: AnnotatedRegion(
                      value: SystemUiOverlayStyle.dark,
                      child: child ?? const SizedBox(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}