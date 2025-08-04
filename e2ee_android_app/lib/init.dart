import 'dart:async';
import 'package:e2ee_android_app/views/my_app.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'backend/app_init_controller.dart';
import 'configs/constants.dart';
import 'utils/encryption_service.dart';

// This new function will be called from our AppInitializerScreen.
Future<void> initializeAllServices(BuildContext context) async {
  // Using runZonedGuarded is still a good idea for top-level error catching.
  return runZonedGuarded<Future<void>>(
    () async {
      // 1. Perform all your async initialization here.
      await EncryptionService().init();
      await AppInitController().initApp(appFlavor: AppFlavors.development);

      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize('2b0ded98-42f4-47fa-92a5-4c01713f053d');
      OneSignal.Notifications.requestPermission(true);

      final playerId = await OneSignal.User.getOnesignalId();
      print("📱 OneSignal Player ID: $playerId");

      // 2. When initialization is complete, navigate to the main app.
      // We use pushReplacement so the user can't press "back" to the loading screen.
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
      }
    },
    (e, s) {
      print("Error in runZonedGuarded during initialization: $e");
      print(s);
      // Propagate the error to be caught by the AppInitializerScreen's try-catch block.
      throw e;
    },
  );
}
