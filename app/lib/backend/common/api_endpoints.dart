// =============================================================================
// API Endpoints
// =============================================================================

class ApiEndpoints {
  static String get baseUrl => 'https://172.86.92.130.sslip.io/api';

  // Authentication
  static const String authRegister = '/auth/register';
  static const String authRegister2 = '/auth/register2';
  static const String authLogin = '/auth/login';
  static const String authUser = '/auth/user';
  static String authCheckEmail(String email) =>
      '/auth/check-email/${Uri.encodeComponent(email)}';

  // Chat
  static const String sendMessage = '/send-message';
  static const String getOpponent = '/chat/getopponent';
  static String userKeys(String userId) => '/users/$userId/keys';

  // WebRTC
  static const String webrtcSignal = '/webrtc-signal';

  // Profile
  static const String updateProfile = '/update-profile';
  static const String updateProfilePhoto = '/update-profile';
}
