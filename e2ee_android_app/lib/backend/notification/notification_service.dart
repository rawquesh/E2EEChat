import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:developer';


class NotificationService {
  // Use a private constructor to prevent instantiation
  NotificationService._();

  static Future<void> init() async {
    // Set the log level for debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.none);
    OneSignal.initialize("2b0ded98-42f4-47fa-92a5-4c01713f053d");
    await OneSignal.Notifications.requestPermission(true);
      OneSignal.Location.setShared(false);

    _registerListeners();
  }

  /// Requests notification permission using permission_handler.
  static Future<void> requestPermission() async {
    // final status = await Permission.notification.request();
    // log('Notification permission status: $status');

    // if (status.isPermanentlyDenied) {
    //   log('Notification permission permanently denied. Opening app settings.');
    //   await openAppSettings();
    // }
  }

  static void _registerListeners() {
    // Listener for when a notification is displayed in the foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((OSNotificationWillDisplayEvent event) {
      log("FOREGROUND NOTIFICATION WILL DISPLAY: \n${event.notification.jsonRepresentation()}");
      // Complete the event to allow the notification to be displayed

      event.notification.display();
    });

    // Listener for when a notification is clicked
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent result) {
      log('NOTIFICATION CLICKED: \n${result.notification.jsonRepresentation()}');
      final additionalData = result.notification.additionalData;
      if (additionalData != null) {
        // Handle navigation or other custom actions
        log("Additional Data: $additionalData");
      }
    });
  }

  /// Gets the OneSignal Player ID.
  static Future<String?> getPlayerId() async {
    // The 'optedIn' property is a nullable bool, so we must check for true
    final optedIn = OneSignal.User.pushSubscription.optedIn;
    if (optedIn == true) {
      return OneSignal.User.pushSubscription.id;
    }
    return null;
  }

  /// Tag a user with a key-value pair.
  static Future<void> login({required String userId}) async {
    return OneSignal.login(userId);
  }

  /// Delete a tag from a user.
  static Future<void> logut() async {
    return OneSignal.logout();
  }
}
