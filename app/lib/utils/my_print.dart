import 'package:flutter/foundation.dart';

class MyPrint {
  static void printOnConsole(String message, {String tag = ""}) {
    if (kDebugMode) {
      if (tag.isNotEmpty) {
        debugPrint("[$tag] $message");
      } else {
        debugPrint(message);
      }
    }
  }
}
