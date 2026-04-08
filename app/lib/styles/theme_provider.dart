import 'package:flutter/material.dart';

import '../utils/my_print.dart';
import 'app_theme.dart';
import 'styles.dart';

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

  ThemeData? _lightTheme, _darkTheme;

  ThemeData getLightThemeData() {
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
    if (darkThemeMode) {
      return getDarkThemeData();
    } else {
      return getLightThemeData();
    }
  }
}
