import 'package:e2ee_android_app/app_initializer_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // Initialize the absolute minimum required before runApp.
  // Firebase is a common one.
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  // Now, run the app with a wrapper that will handle initialization.
  runApp(const InitialApp());
}

class InitialApp extends StatelessWidget {
  const InitialApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The MaterialApp is defined here so the Navigator works correctly
    // when we switch from the loading screen to the main app.
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppInitializerScreen(), // Start with our new loader screen.
    );
  }
}
