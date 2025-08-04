import 'dart:async';

import 'package:e2ee_android_app/views/my_app.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'backend/app_init_controller.dart';

Future<void> runErrorSafeApp({required String appFlavor}) async {
  return runZonedGuarded<Future<void>>(
    () async {
      await AppInitController().initApp(appFlavor: appFlavor);

      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize('2b0ded98-42f4-47fa-92a5-4c01713f053d');
      OneSignal.Notifications.requestPermission(true);

      final playerId = await OneSignal.User.getOnesignalId();
      print("📱 OneSignal Player ID: $playerId");

      runApp(const MyApp());
    },
    (e, s) {
      print("Error in runZonedGuarded: $e");
      print(s);
    },
  );
}
