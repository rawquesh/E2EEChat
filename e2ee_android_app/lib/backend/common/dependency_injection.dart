import 'package:e2ee_android_app/backend/chats/chats_provider.dart';
import 'package:e2ee_android_app/backend/webrtc/call_provider.dart';

import '../authentication/authentication_provider.dart';
import 'app_state.dart';
import 'app_theme/app_theme_provider.dart';

class DependencyInjection {
  static final AuthenticationProvider authenticationProvider =
      AuthenticationProvider();
  static final AppThemeProvider appThemeProvider = AppThemeProvider();
  static final ChatProvider chatProvider = ChatProvider();
  static final AppState appState = AppState();
  static final CallProvider callProvider = CallProvider();
}
