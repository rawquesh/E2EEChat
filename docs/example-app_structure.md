# Kehilah App Structure

> **Patreon Clone** -- Flutter application at `app/lib/`

---

## Table of Contents

1. [Directory Structure](#1-directory-structure)
2. [Entry Point & App Initialization](#2-entry-point--app-initialization)
3. [Navigation & Routing](#3-navigation--routing)
4. [Backend / API Layer](#4-backend--api-layer)
5. [State Management](#5-state-management)
6. [Dependency Injection](#6-dependency-injection)
7. [Managers (Singletons)](#7-managers-singletons)
8. [Feature Modules](#8-feature-modules)
9. [Models](#9-models)
10. [Architecture Diagram](#10-architecture-diagram)

---

## 1. Directory Structure

```
app/lib/
├── main.dart                          # Entry point
├── firebase_options.dart               # Firebase configuration
├── backend/
│   ├── app_init_controller.dart       # Bootstraps app: theme, auth check, routing decision
│   ├── common/
│   │   ├── api_service.dart          # Central HTTP client (singleton)
│   │   ├── api_endpoints.dart        # All API endpoint constants
│   │   ├── api_exception.dart         # Custom exception class
│   │   ├── api_response.dart          # Generic response wrapper
│   │   ├── app_controller.dart        # Global app-level variables
│   │   ├── common_provider.dart       # Base ChangeNotifier + list/map/primitive wrappers
│   │   └── dependency_injection.dart   # Manual DI singleton registry
│   ├── authentication/
│   │   ├── authentication_controller.dart  # Auth business logic
│   │   ├── authentication_provider.dart     # Auth state (extends CommonProvider)
│   │   └── authentication_repository.dart   # Auth API calls
│   ├── user/
│   ├── creator/
│   ├── creator_section/
│   ├── post/
│   ├── post_creation/
│   ├── memberships/
│   ├── collections/
│   ├── messaging/
│   │   ├── chat_socket_service.dart   # Socket.IO singleton for real-time chat
│   │   ├── direct_message_controller.dart
│   │   └── direct_message_provider.dart
│   ├── notification/
│   ├── audience/
│   ├── insights_earnings_analytics/
│   ├── insights_memberships_analytics/
│   ├── insights_posts_analytics/
│   ├── payout/
│   ├── promotions/
│   │   ├── discount/
│   │   └── gifts/
│   ├── post_report/
│   ├── user_report/
│   └── user_deletion/
├── constants/                         # All constants (API URLs, app types, shared prefs keys, etc.)
├── helpers/
│   ├── encryption_helper.dart
│   ├── image_helper.dart
│   └── parsing_helper.dart
├── managers/
│   ├── deeplink_manager.dart          # Deep link handler (AppLinks)
│   ├── fcm_manager.dart                # Firebase Cloud Messaging singleton
│   ├── hive_manager.dart               # Local Hive database manager
│   ├── shared_pref_manager.dart        # SharedPreferences wrapper
│   └── font_manager.dart
├── models/
│   ├── audience/
│   ├── chat/
│   ├── collection/
│   ├── common/data_model/
│   │   ├── api_documents_paginated_list_model.dart  # Paginated state for API
│   │   ├── data_paginated_list_model.dart          # Base paginated list
│   │   └── paginated_request_model.dart            # Request model for pagination
│   ├── creator/
│   ├── membership/
│   ├── message/
│   ├── notification/
│   ├── payout/
│   ├── post/
│   ├── promotions/
│   ├── social_link/
│   ├── subscription/
│   └── user/
├── navigation/
│   ├── app_router.dart                # GoRouter configuration (all routes)
│   └── direct_navigator.dart          # Static navigation helpers (DeepLink, FCM handlers)
├── pages/
│   ├── my_app.dart                    # Root widget with MultiProvider
│   ├── tab_state.dart                 # Tab navigation state
│   ├── components/
│   ├── creator/                       # Creator-facing screens
│   └── user/                          # User-facing screens
├── styles/
│   ├── font_manager.dart
│   ├── theme_controller.dart
│   ├── theme_data.dart
│   └── theme_provider.dart            # Light/dark theme toggle
└── utils/
    ├── datetime.dart
    ├── extensions.dart
    ├── my_print.dart                  # Tagged logging utility
    ├── my_safe_state.dart
    ├── my_toast.dart
    └── my_utils.dart                  # UUID, clipboard, formatting, etc.
```

---

## 2. Entry Point & App Initialization

### `main.dart`

The entry point initializes Firebase and runs the app through `AppInitController`.

```dart
// main.dart
Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    AppInitController appInitController = AppInitController();
    await appInitController.initApp();

    runApp(const MyApp());

    // Wait for context to be available, then perform post-launch ops
    BuildContext? context;
    while (context == null || (!context.checkMounted())) {
      context = AppRouter.rootNavigatorKey.currentContext;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    await appInitController.performInitialAppOpeningOperations(
      context: context,
      isNavigatedToOnBoardingScreen: false,
    );
  }, (e, s) { ... });
}
```

### `AppInitController` (`backend/app_init_controller.dart`)

Handles app bootstrap: sets `AppController.appType`, initializes theme, precaches onboarding images, then performs auth-gated routing:

1. Checks if user has stored credentials (`user_id`, `auth_token` in SharedPreferences)
2. Calls `authenticationController.isUserLoggedIn()` to validate the token via the API
3. If not logged in -> navigates to `Routes.login`
4. If logged in and `isCreatorMode` is true -> navigates to `Routes.creatorMain`
5. Otherwise -> navigates to `Routes.main`

---

## 3. Navigation & Routing

### Router: GoRouter

All routing is handled by **GoRouter** (`package:go_router`). The router is configured in [app_router.dart](app/lib/navigation/app_router.dart).

```dart
// navigation/app_router.dart
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: Routes.splash,
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/${Routes.login}',
        name: Routes.login,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/${Routes.postDetails}',
        name: Routes.postDetails,
        builder: (BuildContext context, GoRouterState state) {
          final Map<String, dynamic> args = state.extra as Map<String, dynamic>? ?? {};
          return PostDetailsScreen(
            postId: args['postId'] as String?,
            postModel: args['postModel'] as PostModel?,
          );
        },
      ),
      // ... 35 routes total
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri}')),
    ),
  );
}
```

**Key points:**
- All 35+ named routes use string constants from the `Routes` class
- Route parameters are passed via `state.extra` as `Map<String, dynamic>`
- Navigation uses `context.pushNamed()`, `context.goNamed()`, `context.push()`
- `rootNavigatorKey` is a static `GlobalKey` that enables `DirectNavigator` to access context from anywhere

### Routes Class (named constants)

```dart
// All named route constants
class Routes {
  static const String splash = "splash";
  static const String login = "login";
  static const String signUp = "signUp";
  static const String main = "main";
  static const String postDetails = "postDetails";
  static const String creatorProfile = "creatorProfile";
  static const String chat = "chat";
  static const String messaging = "messaging";
  static const String createTextPost = "createTextPost";
  static const String createVideoPost = "createVideoPost";
  // ... and more
}
```

### DirectNavigator (`navigation/direct_navigator.dart`)

Static helper class for **programmatic navigation** from outside widget trees (e.g., from FCM handlers, DeepLink handlers, notification taps). Uses `AppRouter.rootNavigatorKey.currentContext` to access context anywhere.

```dart
class DirectNavigator {
  static void navigateToTab(int tabIndex, {int messagingTabIndex = 0}) { ... }

  static Future<void> navigateToPostDetails(String postId) async {
    BuildContext? context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null) {
      PostModel? postModel = await PostRepository().getPostById(postId: postId);
      if (postModel != null) {
        context.pushNamed(Routes.postDetails, extra: {'postModel': postModel, 'postId': postId});
      }
    }
  }

  static Future<void> navigateToCreatorPage(String username) async { ... }
  static Future<void> navigateToChat(String chatId, {required bool isGroupChat}) async { ... }
  static Future<void> navigateToMainScreen(BuildContext context, {bool forceRefresh = false}) async { ... }
  static Future<void> navigateToCreatorMainScreen(BuildContext context) async { ... }
}
```

### TabState (`pages/tab_state.dart`)

Simple `ChangeNotifier` holding the current bottom tab index for the main screen:

```dart
class TabState extends ChangeNotifier {
  int _currentIndex = 0;
  int _messagingTabIndex = 0;

  void setTab(int index, {int messagingTabIndex = 0}) {
    _currentIndex = index;
    _messagingTabIndex = messagingTabIndex;
    notifyListeners();
  }
}
```

### MyApp (`pages/my_app.dart`)

Registers all providers and bootstraps the GoRouter-backed `MaterialApp`:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticationProvider>.value(
            value: DependencyInjection.authenticationProvider),
        ChangeNotifierProvider<PostProvider>.value(value: DependencyInjection.postProvider),
        // ... all 17 providers registered
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: Consumer<AppThemeProvider>(
        builder: (context, appThemeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            theme: appThemeProvider.getThemeData(),
            // ...
          );
        },
      ),
    );
  }
}
```

---

## 4. Backend / API Layer

### API Service (`backend/common/api_service.dart`)

**Central singleton HTTP client** built on `package:http` (NOT Dio). Handles all HTTP communication with automatic Bearer token injection, logging, and error handling.

```dart
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => ApiUrls.prodBaseUrl; // 'https://kehilahserver.com'

  // Core HTTP methods
  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint, {Map<String, String>? queryParams,
      bool includeAuth = true, Map<String, String>? customHeaders}) async { ... }

  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint, {Object? body,
      Map<String, String>? queryParams, bool includeAuth = true, ...}) async { ... }

  Future<ApiResponse<Map<String, dynamic>>> put(String endpoint, {Object? body,
      Map<String, String>? queryParams, bool includeAuth = true, ...}) async { ... }

  Future<ApiResponse<Map<String, dynamic>>> delete(String endpoint, {Object? body,
      Map<String, String>? queryParams, bool includeAuth = true, ...}) async { ... }

  // Multipart file uploads
  Future<ApiResponse<Map<String, dynamic>>> multipartRequest({
      required String method, required String endpoint,
      Map<String, String>? fields, List<MultipartFileData>? files, bool includeAuth = true}) async { ... }

  // Raw requests for external APIs (e.g., S3)
  Future<http.Response> rawRequest({required String method, required String url,
      Map<String, String>? headers, List<int>? bodyBytes}) async { ... }

  // Built-in pagination with deduplication and cache checking
  Future<void> getPaginatedList<T>(PaginatedRequestModel<T> request) async { ... }

  // Throwing variants for try/catch error handling
  Future<Map<String, dynamic>> getOrThrow(...) async { ... }
  Future<Map<String, dynamic>> postOrThrow(...) async { ... }
  Future<Map<String, dynamic>> putOrThrow(...) async { ... }
  Future<Map<String, dynamic>> deleteOrThrow(...) async { ... }
}
```

**Key features:**
- **Automatic Bearer token** from SharedPreferences (`auth_token`)
- All requests logged with unique tags via `MyPrint`
- Throwing variants (`getOrThrow`, etc.) for exception-based handling
- Built-in pagination with ID-based deduplication, cache checking, and state management

### API Response Wrapper (`backend/common/api_response.dart`)

Generic wrapper for all API responses:

```dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final int statusCode;
  final String? message;
  final String? errorMessage;

  factory ApiResponse.success({required T data, required int statusCode, String? message}) { ... }
  factory ApiResponse.error({required int statusCode, required String errorMessage, T? data}) { ... }

  bool get hasData => data != null;
  T get dataOrThrow { ... }       // throws if null
  T dataOr(T fallback) => data ?? fallback;
}
```

### API Exception (`backend/common/api_exception.dart`)

Custom exception for API errors with helpful predicates:

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;
  final String? endpoint;

  bool get isAuthError    => statusCode == 401 || statusCode == 403;
  bool get isNotFound     => statusCode == 404;
  bool get isServerError  => statusCode >= 500 && statusCode < 600;
  bool get isClientError  => statusCode >= 400 && statusCode < 500;
  bool get isNetworkError => statusCode == 0;

  factory ApiException.networkError({String? endpoint}) { ... }
  factory ApiException.timeout({String? endpoint}) { ... }
}
```

### API Endpoints (`backend/common/api_endpoints.dart`)

All endpoint constants organized by domain:

```dart
class ApiEndpoints {
  // AUTHENTICATION
  static const String authGoogleMobile = '/auth/google/mobile';
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authUser = '/auth/user';
  static String authCheckEmail(String email) => '/auth/check-email/$email';

  // USERS
  static const String usersProfile = '/users/profile';
  static const String usersProfilePhoto = '/users/profile/photo';
  // ...

  // POSTS
  static const String postsText = '/posts/text';
  static String post(String id) => '/posts/$id';
  static String postComments(String postId) => '/posts/$postId/comments';
  static String postLike(String postId) => '/posts/$postId/like';
  // ...

  // MEMBERSHIPS, COLLECTIONS, CHAT, ANALYTICS, PROMOTIONS, etc.
}
```

### API Constants (`constants/api_constants.dart`)

```dart
class ApiUrls {
  static const String prodBaseUrl = 'https://kehilahserver.com';
}
```

### Repository Pattern

Each feature has its own repository class that wraps `ApiService`. Example — [authentication_repository.dart](app/lib/backend/authentication/authentication_repository.dart):

```dart
class AuthenticationRepository {
  final ApiService _apiService = ApiService();

  Future<GoogleSignInAccount?> getGoogleAccount() async { ... }

  Future<Map<String, dynamic>?> loginWithGoogleBackend(String accessToken) async {
    final response = await _apiService.post(
      ApiEndpoints.authGoogleMobile,
      body: {'accessToken': accessToken},
      includeAuth: false,  // No token needed for login/register
    );
    if (response.success) return response.data;
    return null;
  }

  Future<Map<String, dynamic>?> signInWithEmail({
      required String email, required String password}) async { ... }

  Future<UserModel?> getUserFromToken(String token) async {
    final response = await _apiService.get(
      ApiEndpoints.authUser,
      customHeaders: {'Authorization': 'Bearer $token'},
      includeAuth: false,
    );
    if (response.success && response.data != null) {
      return UserModel.fromMap(response.data!);
    }
    return null;
  }
}
```

Example — [post_repository.dart](app/lib/backend/post/post_repository.dart):

```dart
class PostRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>?> createCommentOnPost({
      required String postId, required String text, String? parentId}) async {
    final response = await _apiService.post(
      ApiEndpoints.postComments(postId),
      body: {'text': text, if (parentId != null) 'parentId': parentId},
    );
    if (response.success) return response.data;
    return null;
  }

  Future<PostModel?> getPostById({required String postId}) async {
    final response = await _apiService.get(ApiEndpoints.post(postId));
    if (response.success && response.data != null) {
      return PostModel.fromMap(response.data!);
    }
    return null;
  }
}
```

---

## 5. State Management

**Provider + Custom Base Class** — No BLoC, Riverpod, or GetX reactive primitives. The architecture uses a **custom Provider-based system** with three generic wrapper classes.

### CommonProvider Base (`backend/common/common_provider.dart`)

```dart
class CommonProvider extends ChangeNotifier {
  void notify({bool isNotify = true}) {
    if (isNotify) notifyListeners();
  }
}

// Wraps a List<T> with get/set/insert/remove/insertAll
class CommonProviderListParameter<T> {
  List<T> getList({bool isNewInstance = true}) { ... }
  void setList({required List<T> list, bool isClear = true, bool isNotify = true}) { ... }
  void insertAtIndex({required int index, required T model, bool isNotify = true}) { ... }
  void removeObject({required T model, bool isNotify = true}) { ... }
}

// Wraps a Map<K, V> with get/set/clearKey
class CommonProviderMapParameter<K, V> {
  Map<K, V> getMap({bool isNewInstance = true}) { ... }
  void setMap({required Map<K, V> map, bool isClear = true, bool isNotify = true}) { ... }
  void clearKey({required String key, bool isNotify = true}) { ... }
}

// Wraps a primitive value T with get/set
class CommonProviderPrimitiveParameter<T> {
  T get() { return _value; }
  void set({required T value, bool isNotify = true}) { ... }
}
```

### AuthenticationProvider Example

```dart
// backend/authentication/authentication_provider.dart
class AuthenticationProvider extends CommonProvider {
  AuthenticationProvider() {
    userId = CommonProviderPrimitiveParameter<String>(value: "", notify: notify);
    mobileNumber = CommonProviderPrimitiveParameter<String>(value: "", notify: notify);
    email = CommonProviderPrimitiveParameter<String>(value: "", notify: notify);
    userModel = CommonProviderPrimitiveParameter<UserModel?>(value: null, notify: notify);
    loginSessionId = CommonProviderPrimitiveParameter<String>(value: "", notify: notify);
  }

  late CommonProviderPrimitiveParameter<String> userId;
  late CommonProviderPrimitiveParameter<String> mobileNumber;
  late CommonProviderPrimitiveParameter<String> email;
  late CommonProviderPrimitiveParameter<UserModel?> userModel;
  late CommonProviderPrimitiveParameter<String> loginSessionId;

  void resetData({bool isNotify = true}) { ... }

  String get currentUserId => userId.get();
  String get currentEmail => email.get();
  UserModel? get currentUserModel => userModel.get();
}
```

### Controller Pattern

Controllers contain **business logic** and call repositories. They are lightweight service classes (not `ChangeNotifier`). They receive providers and repositories as dependencies.

```dart
// backend/authentication/authentication_controller.dart
class AuthenticationController {
  late AuthenticationProvider _authenticationProvider;
  late AuthenticationRepository _authenticationRepository;

  AuthenticationController({
    AuthenticationProvider? authenticationProvider,
    AuthenticationRepository? repository,
  }) {
    _authenticationProvider = authenticationProvider ?? DependencyInjection.authenticationProvider;
    _authenticationRepository = repository ?? AuthenticationRepository();
  }

  Future<bool> signInWithGoogle({
      required BuildContext context, required GoogleSignInAccount googleUser}) async { ... }

  Future<bool> isUserLoggedIn() async { ... }

  Future<void> onLoginSuccess({required BuildContext context, String authenticationMode = ""}) async {
    UserModel? userModel = await _authenticationRepository.getUserFromToken(_authToken ?? "");
    if (userModel == null) { await logout(isNavigateToLogin: true); return; }
    authenticationProvider.userModel.set(value: userModel, isNotify: true);
    authenticationProvider.userId.set(value: userModel.userId, isNotify: false);
    await SharedPrefManager().setString(SharedPreferenceConstants.authToken, _authToken ?? "");
    if (context.checkMounted() && context.mounted) {
      context.goNamed(Routes.main);
    }
  }

  Future<bool> logout({bool isNavigateToLogin = false, bool isForceLogout = false}) async {
    await _authenticationRepository.signOut();
    await SharedPrefManager().clearAll();
    HiveManager.clearAllData();
    authenticationProvider.resetData(isNotify: true);
    return true;
  }
}
```

---

## 6. Dependency Injection

**Manual DI** — No `get_it`, `injectable`, or code generation. All singletons are registered in a single static class.

```dart
// backend/common/dependency_injection.dart
class DependencyInjection {
  static final AuthenticationProvider authenticationProvider = AuthenticationProvider();
  static final AuthenticationController authenticationController =
      AuthenticationController(authenticationProvider: authenticationProvider);
  static final AppThemeProvider appThemeProvider = AppThemeProvider();
  static final PostProvider postProvider = PostProvider();
  static final MyCreatorProvider myCreatorProvider = MyCreatorProvider();
  static final DirectMessageProvider directMessageProvider = DirectMessageProvider();
  static final ChatSocketService chatSocketService = ChatSocketService();
  static final LikedPostsProvider likedPostsProvider = LikedPostsProvider();
  static final MyNotificationProvider myNotificationProvider = MyNotificationProvider();
  static final PostCreationProvider postCreationProvider = PostCreationProvider();
  static final CollectionProvider collectionProvider = CollectionProvider();
  static final MembershipProvider membershipProvider = MembershipProvider();
  static final DiscountProvider discountProvider = DiscountProvider();
  static final GiftProvider giftProvider = GiftProvider();
  static final MembershipAnalyticsProvider membershipAnalyticsProvider = MembershipAnalyticsProvider();
  static final EarningsAnalyticsProvider earningsAnalyticsProvider = EarningsAnalyticsProvider();
  static final PostsAnalyticsProvider postsAnalyticsProvider = PostsAnalyticsProvider();
  static final PayoutProvider payoutProvider = PayoutProvider();
  static final AudienceProvider audienceProvider = AudienceProvider();
  static final TabState tabState = TabState();
}
```

Providers are then registered with `ChangeNotifierProvider.value` in `MyApp.build()`.

---

## 7. Managers (Singletons)

### DeepLinkManager (`managers/deeplink_manager.dart`)

Handles incoming deep links via `app_links` package. Parses URI paths and navigates:

```dart
class DeepLinkManager {
  static final DeepLinkManager _instance = DeepLinkManager._internal();
  factory DeepLinkManager() => _instance;
  DeepLinkManager._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> init(BuildContext context) async {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _navigateTo(context, uri);
    });
  }

  void _navigateTo(BuildContext context, Uri uri) {
    // /post/{id}      -> navigateToPostDetails(id)
    // /creator/{username} -> navigateToCreatorPage(username)
    // /profile/{id}/chat -> navigateToChat(id, isGroupChat: true)
    // /profile/{id}/direct-messages -> navigateToChat(id, isGroupChat: false)
  }
}
```

### FCMManager / NotificationManager (`managers/fcm_manager.dart`)

Singleton managing Firebase Cloud Messaging and local notifications:

- Requests FCM permission
- Gets/uploads FCM token
- Sets up foreground and background message handlers
- Shows local notifications via `FlutterLocalNotificationsPlugin`
- On notification tap: extracts `postId`/`chatId`/`notificationType` from payload and calls `DirectNavigator`
- Subscribes to `test` topic in debug mode

```dart
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._();
  static NotificationManager get instance => _instance;

  Future<void> initialize() async {
    await _requestPermission();
    await _initializeLocalNotifications();
    final fcmToken = await getFcmToken();
    await _handleTokenUpdate(fcmToken);
    _onTokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(_handleTokenUpdate);
    _setupMessageHandlers();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    // POST_LIKE / NEW_COMMENT -> navigateToPostDetails
    // CHAT_MESSAGE -> navigateToChat(isGroupChat: true)
    // DIRECT_MESSAGE -> navigateToMessagingTab(isGroupChat: false)
  }
}
```

### SharedPrefManager (`managers/shared_pref_manager.dart`)

Singleton wrapper around `shared_preferences` for key-value persistence. Key constants defined in `constants/shared_preference_constants.dart`:
- `auth_token`, `user_id` — auth state
- `isCreatorMode` — user vs creator mode toggle
- `loginSessionId` — per-session tracking
- `fcmToken` — Firebase token
- `darkThemeModeEnabled` — theme preference
- `isFirst` — first-launch detection

### HiveManager (`managers/hive_manager.dart`)

Singleton for local NoSQL storage (Hive). Used for persisting liked posts locally and other offline-capable data.

---

## 8. Feature Modules

Each feature follows the same 3-layer pattern:

| Layer | Purpose |
|---|---|
| **Repository** | Calls `ApiService`, returns parsed models |
| **Controller** | Business logic, orchestrates repository calls |
| **Provider** | Holds reactive state (extends `CommonProvider`) |

### Authentication (`backend/authentication/`)

- Google Sign-In (native popup + backend token exchange)
- Email/password login
- Registration
- Token validation on startup
- Logout clears all persisted state

### Posts (`backend/post/`, `backend/post_creation/`)

- Post types: text, video, audio, image, link
- Drafts (separate endpoints)
- Like/unlike with optimistic UI via `LikedPostsProvider`
- Comments with replies
- Content visibility (tier-based access)
- Post creation with multipart file uploads

### Messaging (`backend/messaging/`)

Real-time chat via **Socket.IO** (`ChatSocketService`):

```dart
// backend/messaging/chat_socket_service.dart
class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;

  io.Socket? _socket;

  Future<void> connect({required String token}) async {
    _socket = io.io('${ApiUrls.prodBaseUrl}/chat', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
    });
    _socket!.on('connect', (_) { ... });
    _socket!.on('new_message', (data) { _currentNewMessageHandler?.call(data); });
    _socket!.connect();
  }

  void joinChat(String chatId)   => _socket?.emit('join_chat', {'chatId': chatId});
  void leaveChat(String chatId)  => _socket?.emit('leave_chat', {'chatId': chatId});
  void sendMessage(String chatId, String message)
      => _socket?.emit('send_message', {'chatId': chatId, 'message': {'content': message}});

  void onNewMessage(Function(dynamic) handler) { ... }
  void offNewMessage() { ... }
  bool get isConnected => _socket?.connected ?? false;
}
```

### Memberships (`backend/memberships/`)

- Creator memberships listing
- Membership checkout (Stripe)
- Free subscription
- Unsubscribe

### Collections (`backend/collections/`)

- CRUD for creator collections
- Collection posts listing

### Promotions (`backend/promotions/`)

- **Discounts**: create/edit/list percentage or fixed discounts (time-limited)
- **Gifts**: create/edit/list free memberships

### Analytics (`backend/insights_*_analytics/`)

- Earnings analytics: total, growth %, monthly/tier breakdown
- Membership analytics
- Post analytics: views, likes, comments per post

### Reports (`backend/post_report/`, `backend/user_report/`)

- Report reasons list
- Report posts and users

---

## 9. Models

All models follow a `fromMap` / `toMap` pattern for JSON serialization:

```dart
class UserModel {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final bool isCreator;
  final String? creatorHeadline;
  final String? creatorCategory;
  final String? bio;
  final List<SocialLinkModel> socialLinks;
  final StripeOnboardingStatus stripeOnboardingStatus;
  // ... many more fields

  factory UserModel.fromMap(Map<String, dynamic> map) { ... }
  Map<String, dynamic> toMap() { ... }
}
```

Key model files:
- [models/user/data_model/user_model.dart](app/lib/models/user/data_model/user_model.dart)
- [models/post/data_model/post_model.dart](app/lib/models/post/data_model/post_model.dart)
- [models/creator/creator_model.dart](app/lib/models/creator/creator_model.dart)
- [models/membership/membership_model.dart](app/lib/models/membership/membership_model.dart)
- [models/chat/chat_model.dart](app/lib/models/chat/chat_model.dart)
- [models/notification/notification_model.dart](app/lib/models/notification/notification_model.dart)

### Paginated List Model

Custom pagination system for consistent infinite scroll:

```dart
// Base paginated list with loading/hasMore state
class DataDocumentsPaginatedListModel<T> extends CommonProvider {
  late CommonProviderListParameter<T> contentsList;
  late CommonProviderPrimitiveParameter<int> pageIndex;
  late CommonProviderPrimitiveParameter<int> contentsDocumentLimitForPagination;
  late CommonProviderPrimitiveParameter<bool> hasMoreContents;
  late CommonProviderPrimitiveParameter<bool> isContentsFirstTimeLoading;
  late CommonProviderPrimitiveParameter<bool> isContentsLoading;

  void reset({bool isNotify = true}) { ... }
}

// API-aware version with current/total page tracking
class APIDocumentsPaginatedListModel<T> extends DataDocumentsPaginatedListModel<T> {
  late CommonProviderPrimitiveParameter<int> currentPage;
  late CommonProviderPrimitiveParameter<int> totalPages;
  // ...
}
```

---

## 10. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                              main.dart                               │
│  Firebase init -> AppInitController -> MyApp -> runApp              │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
┌────────────────────────────────▼────────────────────────────────────┐
│                            MyApp                                     │
│         MultiProvider (17 ChangeNotifierProviders)                   │
│                   MaterialApp.router (GoRouter)                      │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
           ┌─────────────────────┼─────────────────────┐
           │                     │                     │
┌──────────▼──────┐   ┌──────────▼──────┐   ┌─────────▼─────────┐
│  User Screens   │   │ Creator Screens │   │ Navigation Layer  │
│  (pages/user/)  │   │  (pages/creator/)│   │  app_router.dart  │
│                 │   │                 │   │  Routes class     │
└─────────────────┘   └─────────────────┘   │  DirectNavigator  │
                                             └─────────────────────┘
                                                       │
┌──────────────────────────────────────────────────────▼──────────────────┐
│                    Backend Layer (backend/)                               │
│                                                                        │
│  ┌────────────────┐    ┌─────────────────────┐    ┌─────────────────┐ │
│  │ Controllers     │───▶│ Repositories         │───▶│   ApiService     │ │
│  │ (Business       │    │ (1 per feature,       │    │   (Singleton)    │ │
│  │  logic)         │    │  wraps ApiService)    │    │   package:http   │ │
│  └────────────────┘    └─────────────────────┘    └────────┬────────┘ │
│                                                            │          │
│  ┌────────────────┐    ┌─────────────────────┐            │          │
│  │ Providers       │◀───│ CommonProvider       │◀───────────┘          │
│  │ (State: list,  │    │ (ChangeNotifier +    │                       │
│  │  map, primitive│    │  3 param wrappers)    │                       │
│  │  wrappers)     │    └─────────────────────┘                       │
│  └────────────────┘                                                   │
└────────────────────────────────┬───────────────────────────────────────┘
                                 │
           ┌─────────────────────┼─────────────────────┐
           │                     │                     │
┌──────────▼──────┐   ┌──────────▼──────┐   ┌─────────▼─────────┐
│   Managers      │   │    Models       │   │   Constants       │
│ (Singletons)   │   │ (fromMap/toMap) │   │   (API URLs,     │
│                 │   │                 │   │    keys)          │
│ DeepLinkManager │   │ UserModel       │   │                   │
│ NotificationMgr │   │ PostModel       │   │ ApiEndpoints      │
│ SharedPrefMgr   │   │ CreatorModel    │   │ SharedPrefKeys    │
│ HiveManager     │   │ MembershipModel│   │ AppConstants      │
│ ChatSocketSvc   │   │ ChatModel      │   │                   │
└─────────────────┘   └─────────────────┘   └──────────────────┘
```

### Data Flow Summary

| Action | Flow |
|---|---|
| **API Call** | Widget calls `Controller` method -> `Controller` calls `Repository` -> `Repository` calls `ApiService` -> returns `ApiResponse` -> `Controller` parses to `Model` -> updates `Provider` state |
| **Navigation** | User action -> `context.pushNamed(Routes.xxx, extra: {...})` -> GoRouter matches route -> builds screen widget |
| **State** | Provider holds state as `CommonProviderPrimitiveParameter` / `ListParameter` / `MapParameter` -> Widget reads via `Consumer<T>` or `context.watch<T>()` -> `notifyListeners()` triggers rebuild |
| **Deep Link / FCM** | System delivers link/notification -> `DeepLinkManager` / `NotificationManager` parses URI/payload -> calls `DirectNavigator` static method -> accesses `rootNavigatorKey.currentContext` -> navigates |
| **Real-time Chat** | `ChatSocketService` singleton manages Socket.IO connection -> `onNewMessage` handler receives events -> updates `DirectMessageProvider` -> UI rebuilds via `notifyListeners()` |
