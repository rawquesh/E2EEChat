import 'package:e2ee_android_app/utils/encryption_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'configs/constants.dart';
import 'init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EncryptionService().init();
  await Firebase.initializeApp();

  await runErrorSafeApp(appFlavor: AppFlavors.development);
}
