import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:e2ee_android_app/configs/constants.dart';
import 'package:e2ee_android_app/core/storage_manager.dart';
import 'package:flutter/material.dart';

/// A custom dialog widget that matches the provided screenshot.
class BatteryOptimizationDialog extends StatelessWidget {
  const BatteryOptimizationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: const Color(0xFF2E2E2E), // A dark grey color
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Battery optimizations enabled',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Your device is employing heavy battery optimizations for DarkCrypt Chat which may lead to delayed notifications or even message loss.',
              style: TextStyle(fontSize: 16.0, color: Colors.white70),
            ),
            const SizedBox(height: 16.0),
            const Text('You will now be asked to disable them.', style: TextStyle(fontSize: 16.0, color: Colors.white70)),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                  await SharedPrefManager().setBool(MySharedPreferenceVariables.batteryOptimizationRequested, true);
                },
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Color(0xFF66BB6A), // A light green color
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
