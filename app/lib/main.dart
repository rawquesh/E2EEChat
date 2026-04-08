import 'dart:async';

import 'package:e2ee_android_app/backend/app_init_controller.dart';
import 'package:e2ee_android_app/backend/notification/notification_service.dart';
import 'package:e2ee_android_app/helpers/encryption_helper.dart';
import 'package:e2ee_android_app/navigation/app_router.dart';
import 'package:e2ee_android_app/pages/my_app.dart';
import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await EncryptionHelper().init();
      NotificationService.init();

      AppInitController appInitController = AppInitController();
      await appInitController.initApp(appFlavor: 'development');

      runApp(const MyApp());

      BuildContext? context;
      while (context == null || (!context.mounted)) {
        context = AppRouter.rootNavigatorKey.currentContext;
        await Future.delayed(const Duration(milliseconds: 400));
      }
      await appInitController.performInitialAppOpeningOperations(
        context: context,
        isNavigatedToOnBoardingScreen: false,
      );
    },
    (e, s) {
      MyPrint.printOnConsole("Error in runZonedGuarded:$e");
      MyPrint.printOnConsole(s.toString());
    },
  );
}
