import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

import '../utils/storage_manager.dart';

class MyPrint {
  static String _logData = "";
  static bool? _isRecordLog;

  static bool? get isRecordLog => _isRecordLog;

  static void printOnConsole(Object s, {String? tag}) {
    if (kDebugMode) {
      MyPrint.printOnConsole("${(tag?.isNotEmpty ?? false) ? "$tag " : ""}${s.toString()}");
    }
  }

  static void logOnConsole(Object s, {String? tag}) {
    developer.log("${(tag?.isNotEmpty ?? false) ? "$tag " : ""}${s.toString()}");
  }

  static void appendLogData({required String logMessage}) {
    if (_isRecordLog ?? false) _logData += "\n$logMessage";
  }

  static void setIsRecordLog(bool isRecord) => _isRecordLog = isRecord;

  static String getLog() {
    String log = _logData;
    developer.log("log length:${log.length}");

    _logData = "";

    return log;
  }

  static void toggleRecordLog({bool? isRecord}) {
    _isRecordLog = isRecord ?? !(_isRecordLog ?? true);

    String key = "_isRecordLog";
    SharedPrefManager().setBool(key, _isRecordLog!);
  }
}
