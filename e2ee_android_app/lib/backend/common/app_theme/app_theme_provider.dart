import 'package:e2ee_models_app/configs/styles.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:flutter/material.dart';

import '../../../configs/app_theme.dart';

class AppThemeProvider extends ChangeNotifier {
  bool _darkThemeMode = false;

  bool get darkThemeMode => _darkThemeMode;

  void setDarkThemeMode({bool isDarkThemeEnabled = false, bool isNotify = true}) {
    _darkThemeMode = isDarkThemeEnabled;
    if (isNotify) notifyListeners();
  }

  void toggleThemeMode({bool isNotify = true}) {
    _darkThemeMode = !_darkThemeMode;
    if (isNotify) notifyListeners();
  }

  void resetThemeMode({bool isNotify = true}) {
    _darkThemeMode = true;
    if (isNotify) notifyListeners();
  }

  //region ThemeData

  ThemeData? _lightTheme, _darkTheme;

  ThemeData getLightThemeData() {
    // MyPrint.printOnConsole("getLightThemeData called with _lightTheme:$_lightTheme");
    if (_lightTheme == null) {
      MyPrint.printOnConsole("_instancyThemeColors.appButtonBgColor:");

      Styles styles = Styles();
      MyPrint.printOnConsole("styles:$styles");
      _lightTheme = AppTheme(styles: styles).getLightTheme();
    }
    return _lightTheme!;
  }

  ThemeData getDarkThemeData() {
    if (_darkTheme == null) {
      Styles styles = Styles();
      MyPrint.printOnConsole("styles:$styles");
      _darkTheme = AppTheme(styles: styles).getDarkTheme();
    }
    return _darkTheme!;
  }

  ThemeData getThemeData() {
    // MyPrint.printOnConsole("getThemeData calld with darkThemeMode:$darkThemeMode");

    if (darkThemeMode) {
      return getDarkThemeData();
    } else {
      return getLightThemeData();
    }
  }
//endregion
}
