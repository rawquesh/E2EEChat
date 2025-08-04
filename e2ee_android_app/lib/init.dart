import 'dart:async';

import 'package:e2ee_android_app/utils/encryption_service.dart';
import 'package:e2ee_android_app/views/my_app.dart';
import 'package:e2ee_models_app/utils/extensions.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'backend/app_init_controller.dart';
import 'backend/navigation/navigation_controller.dart';

Future<void>? runErrorSafeApp({required String appFlavor}) {
  return runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await EncryptionService().init();

      await Firebase.initializeApp();

      AppInitController appInitController = AppInitController();

      await appInitController.initApp(appFlavor: appFlavor);

      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      OneSignal.initialize('2b0ded98-42f4-47fa-92a5-4c01713f053d');

      OneSignal.Notifications.requestPermission(true);

      final playerId = await OneSignal.User.getOnesignalId();
      print("📱 OneSignal Player ID: $playerId");

      runApp(const MyApp());

      BuildContext? context;
      while (context == null || (!context.checkMounted())) {
        context = NavigationController.mainScreenNavigator.currentContext;
        await Future.delayed(const Duration(milliseconds: 400));
      }
      await appInitController.performInitialAppOpeningOperations(context: context, isNavigatedToOnBoardingScreen: false);
    },
    (e, s) {
      MyPrint.printOnConsole("Error in runZonedGuarded:$e");
      MyPrint.printOnConsole(s);
    },
  );
}
