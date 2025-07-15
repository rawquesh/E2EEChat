import '../authentication/authentication_provider.dart';
import 'app_theme/app_theme_provider.dart';

class DependencyInjection {
  static final AuthenticationProvider authenticationProvider = AuthenticationProvider();
  static final AppThemeProvider appThemeProvider = AppThemeProvider();
}
