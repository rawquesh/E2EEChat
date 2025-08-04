import 'package:e2ee_android_app/init.dart';
import 'package:flutter/material.dart';

class AppInitializerScreen extends StatefulWidget {
  const AppInitializerScreen({Key? key}) : super(key: key);

  @override
  State<AppInitializerScreen> createState() => _AppInitializerScreenState();
}

class _AppInitializerScreenState extends State<AppInitializerScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // This function now contains all your original setup logic.
      // We pass the context so we can navigate away when it's done.
      await initializeAllServices(context);
    } catch (e, s) {
      // If something goes wrong during initialization, you can handle it here.
      // For example, navigate to a dedicated error screen.
      print("FATAL: Failed to initialize app: $e");
      print(s);
      // Example:
      // if (mounted) {
      //   Navigator.of(context).pushReplacement(
      //     MaterialPageRoute(builder: (_) => const ErrorScreen()),
      //   );
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the loading UI the user will see immediately.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
