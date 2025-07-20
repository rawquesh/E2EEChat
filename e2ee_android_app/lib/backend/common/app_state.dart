import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

class AppState extends ChangeNotifier {
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  String? _currentChattingWithUserId;

  bool _showInAppNotification = false;
  String _notificationTitle = '';
  String _notificationBody = '';

  AppLifecycleState get lifecycleState => _lifecycleState;
  String? get currentChattingWithUserId => _currentChattingWithUserId;
  bool get showInAppNotification => _showInAppNotification;
  String get notificationTitle => _notificationTitle;
  String get notificationBody => _notificationBody;

  void setLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  void setCurrentChattingWithUserId(String? userId) {
    _currentChattingWithUserId = userId;
    notifyListeners();
  }

  void showCustomNotification(String title, String? body) {
    _notificationTitle = title;
    _notificationBody = "";
    _showInAppNotification = true;
    notifyListeners();

    showSimpleNotification(
      Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(body ?? "", style: const TextStyle(color: Colors.white70)),
      background: Colors.black87,
      autoDismiss: true,
      duration: const Duration(seconds: 4),
    );

    Future.delayed(const Duration(seconds: 4), hideCustomNotification);
  }

  void hideCustomNotification() {
    _showInAppNotification = false;
    notifyListeners();
  }
}