import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'my_print.dart';

class MyToast {
  static _showToast({
    required BuildContext context,
    required String msg,
    int duration = 2,
    required Color toastColor,
    required Color textColor,
    IconData? iconData,
    Color? iconColor,
    double? iconSize,
    double? positionFromBottom,
  }) {
    try {
      Widget toast = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: toastColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconData != null) ...[
              Icon(
                iconData,
                color: iconColor ?? Colors.white,
                size: iconSize ?? 24,
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                msg,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      );

      FToast fToast = FToast();
      fToast.init(context);
      fToast.removeCustomToast();

      /*fToast.showToast(
        child: toast,
        gravity: ToastGravity.BOTTOM,
        toastDuration: Duration(seconds: duration ?? 2),
      );*/

      // Custom Toast Position
      fToast.showToast(
        child: toast,
        toastDuration: Duration(seconds: duration),
        positionedToastBuilder: (context, child, gravity) {
          return Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom + (positionFromBottom ?? 100.0),
            left: 0,
            right: 0,
            child: child,
          );
        },
      );
    } catch (e, s) {
      MyPrint.printOnConsole("Error in Showing Toast:$e");
      MyPrint.printOnConsole(s);
    }
  }

  static void showError({required BuildContext context, required String msg, IconData? iconData, Color? iconColor, int durationInSeconds = 2}) {
    _showToast(context: context, msg: msg, duration: durationInSeconds, toastColor: Colors.red, textColor: Colors.white, iconData: iconData, iconColor: iconColor);
  }

  static void showSuccess({required BuildContext context, required String msg, IconData? iconData, Color? iconColor, int durationInSeconds = 2}) {
    _showToast(context: context, msg: msg, duration: durationInSeconds, toastColor: Colors.green, textColor: Colors.white, iconData: iconData, iconColor: iconColor);
  }

  static void normalMsg({required BuildContext context, required String msg, IconData? iconData, Color? iconColor, int durationInSeconds = 2}) {
    ThemeData themeData = Theme.of(context);
    _showToast(context: context, msg: msg, duration: durationInSeconds, toastColor: themeData.colorScheme.primary, textColor: Colors.white, iconData: iconData, iconColor: iconColor);
  }

  static void greyMsg({required BuildContext context, required String msg, IconData? iconData, Color? iconColor, int durationInSeconds = 2}) {
    ThemeData themeData = Theme.of(context);
    _showToast(context: context, msg: msg, duration: durationInSeconds, toastColor: themeData.colorScheme.onSurface, textColor: Colors.white, iconData: iconData, iconColor: iconColor);
  }

  static void showCustomToast({
    required BuildContext context,
    required String msg,
    Color? toastColor,
    Color? textColor,
    IconData? iconData,
    Color? iconColor,
    double? iconSize,
    int durationInSeconds = 2,
  }) {
    ThemeData themeData = Theme.of(context);
    _showToast(
      context: context,
      msg: msg,
      toastColor: toastColor ?? themeData.colorScheme.onSurface,
      textColor: textColor ?? Colors.white,
      iconData: iconData,
      iconColor: iconColor,
      iconSize: iconSize,
      duration: durationInSeconds,
    );
  }
}
