// =============================================================================
// API Endpoints & External Service URLs
// Single source of truth for all backend URLs, endpoints, and service config
// =============================================================================

class ApiEndpoints {
  // ---------------------------------------------------------------------------
  // API Server
  // ---------------------------------------------------------------------------
  // LOCAL DEV:     http://localhost:3000/api
  // PRODUCTION:    https://e2ee-api.up.railway.app/api  (update after Railway deploy)
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static String get baseUrl => apiBaseUrl;

  // ---------------------------------------------------------------------------
  // WebRTC STUN/TURN servers (for WebRTCService)
  // ---------------------------------------------------------------------------
  // Uses Google's public STUN server. Replace TURN config with your own
  // coturn/Janus server for production. See backend/.env TURN_* values.
  static const String stunServer = 'stun:stun.l.google.com:19302';
  static const String turnHost = 'REPLACE_WITH_TURN_HOST';
  static const int turnPort = 3478;
  static const int turnsPort = 5349;
  static const String turnUsername = 'REPLACE_WITH_TURN_USER';
  static const String turnCredential = 'REPLACE_WITH_TURN_PASS';

  // ---------------------------------------------------------------------------
  // Soketi WebSocket (shared between ChatRepository & WebRTCSignalingRepository)
  // ---------------------------------------------------------------------------
  // LOCAL DEV:     pusherHost = 'localhost', pusherKey = 'app-key'
  // PRODUCTION:    pusherHost = 'e2ee-soketi.up.railway.app', pusherKey = your Soketi app key
  // Generate app key: node -e "console.log(require('crypto').randomBytes(16).toString('hex'))"
  // Must match SOKETI_APP_KEY in backend/.env and Railway variables.
  static const String pusherKey = 'app-key';
  // Leave pusherHost/pusherWsPort as-is for Soketi's managed cloud service.
  static const String pusherHost = 'localhost';
  static const int pusherWsPort = 80;
  static const int pusherWssPort = 443;
  static const bool pusherEncrypted = true;
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

  // ---------------------------------------------------------------------------
  // Offline Message Polling (fetches messages delivered while app was offline)
  // ---------------------------------------------------------------------------
  static const String pendingMessages = '/pending-messages';
  static String get urlPendingMessages => '$apiBaseUrl$pendingMessages';
}
