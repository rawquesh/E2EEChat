import '../constants/app_constants.dart';
import '../managers/shared_pref_manager.dart';
import 'theme_provider.dart';

class AppThemeController {
  final AppThemeProvider _appThemeProvider;

  AppThemeController({required AppThemeProvider appThemeProvider})
      : _appThemeProvider = appThemeProvider;

  Future<void> init() async {
    bool? isDarkMode = await SharedPrefManager().getBool(
      MySharedPreferenceVariables.darkThemeModeEnabled,
    );

    _appThemeProvider.setDarkThemeMode(
      isDarkThemeEnabled: isDarkMode ?? false,
      isNotify: false,
    );
  }
}
