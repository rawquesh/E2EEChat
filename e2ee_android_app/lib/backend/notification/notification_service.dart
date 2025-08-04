import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> init() async {
    OneSignal.initialize('YOUR-ONESIGNAL-APP-ID');
    OneSignal.Notifications.requestPermission(true);
  }

  Future<bool?> requestNotificationPermissions() async {
    // OneSignal handles this internally, but you can still call:
    await OneSignal.Notifications.requestPermission(true);
    return true;
  }

  /*Future<void> showSystemNotification(int id, String title, String body) async {
    OneSignal.Notifications.displayNotification(
      OneSignal.Notifications(
        id: id.toString(),
        title: title,
        body: body,
      ),
    );
  }*/

  Future<void> getPlayerId() async {
    String? playerId = OneSignal.User.pushSubscription.id;
    print("📱 Player ID: $playerId");
  }
}
