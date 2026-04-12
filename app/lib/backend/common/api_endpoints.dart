// =============================================================================
// API Endpoints & External Service URLs
// Single source of truth for all backend URLs, endpoints, and service config
// =============================================================================

class ApiEndpoints {
  // ---------------------------------------------------------------------------
  // API Server
  // ---------------------------------------------------------------------------
  static const String apiBaseUrl = 'https://172.86.92.130.sslip.io/api';
  static String get baseUrl => apiBaseUrl;

  // ---------------------------------------------------------------------------
  // WebRTC STUN/TURN servers (for WebRTCService)
  // ---------------------------------------------------------------------------
  static const String stunServer = 'stun:stun.l.google.com:19302';
  static const String turnHost = '172.86.92.130.sslip.io';
  static const int turnPort = 3478;
  static const int turnsPort = 5349;
  static const String turnUsername = 'webrtcuser';
  static const String turnCredential = 'webrtccred';

  // ---------------------------------------------------------------------------
  // Pusher / WebSocket (shared between ChatRepository & WebRTCSignalingRepository)
  // ---------------------------------------------------------------------------
  static const String pusherKey = 'sip6lkxyrl3d0um6vbv9';
  static const String pusherCluster = 'mt1';
  static const String pusherHost = '172.86.92.130.sslip.io';
  static const int pusherWsPort = 8080;
  static const int pusherWssPort = 443;
  static const bool pusherEncrypted = false;
  static String get pusherBroadcastingAuthUrl =>
      '$apiBaseUrl/broadcasting/auth';

  // ---------------------------------------------------------------------------
  // WebRTC ICE servers config
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> get iceServers => {
        'iceServers': [
          {'urls': stunServer},
          {
            'urls': [
              'turn:$turnHost:$turnPort?transport=udp',
              'turn:$turnHost:$turnPort?transport=tcp',
              'turns:$turnHost:$turnsPort?transport=tcp',
            ],
            'username': turnUsername,
            'credential': turnCredential,
          },
        ],
      };

  // ---------------------------------------------------------------------------
  // API Endpoints
  // ---------------------------------------------------------------------------

  // Authentication
  static const String authRegister = '/auth/register';
  static const String authRegister2 = '/auth/register2';
  static const String authLogin = '/auth/login';
  static const String authUser = '/auth/user';
  static const String authCheckEmail = '/auth/check-email';

  // Chat
  static const String sendMessage = '/send-message';
  static const String getOpponent = '/chat/getopponent';
  static const String userKeys = '/users';

  // WebRTC
  static const String webrtcSignal = '/webrtc-signal';

  // Profile
  static const String updateProfile = '/update-profile';
  static const String updateProfilePhoto = '/update-profile';

  // ---------------------------------------------------------------------------
  // Derived endpoint helpers
  // ---------------------------------------------------------------------------
  static String authCheckEmailFor(String email) =>
      '$authCheckEmail/${Uri.encodeComponent(email)}';

  static String userKeysFor(String userId) => '$userKeys/$userId/keys';

  // ---------------------------------------------------------------------------
  // Full URL helpers (for repositories that build URLs manually)
  // ---------------------------------------------------------------------------
  static String get urlAuthRegister => '$apiBaseUrl$authRegister';
  static String get urlAuthRegister2 => '$apiBaseUrl$authRegister2';
  static String get urlAuthLogin => '$apiBaseUrl$authLogin';
  static String get urlAuthUser => '$apiBaseUrl$authUser';
  static String urlAuthCheckEmail(String email) =>
      '$apiBaseUrl${authCheckEmailFor(email)}';
  static String get urlSendMessage => '$apiBaseUrl$sendMessage';
  static String get urlGetOpponent => '$apiBaseUrl$getOpponent';
  static String urlUserKeys(String userId) => '$apiBaseUrl${userKeysFor(userId)}';
  static String get urlWebrtcSignal => '$apiBaseUrl$webrtcSignal';
  static String get urlUpdateProfile => '$apiBaseUrl$updateProfile';
}
