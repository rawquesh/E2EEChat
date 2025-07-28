class SharedPreferenceVariables {
  static const String darkThemeModeEnabled = "darkThemeModeEnabled";
  static const String isUserLoggedIn = "isUserLoggedIn";
}

class ApiUrls {
  // static const String devBaseUrl = 'http://172.20.10.4:8080';
  static const String prodBaseUrl = 'https://kehilahserver.com';
}

class AuthenticationModes {
  static const String google = "Google";
  static const String apple = "Apple";
  static const String phoneNumber = "Phone Number";
  static const String email = "email";
}

class PostTypes {
  static const String text = "text";
  static const String image = "image";
  static const String audio = "audio";
  static const String video = "video";
  static const String link = "link";

  static List<String> get values => [text, image, audio, video, link];
}

// liked,
// commented,
// newMember,
// upgrade,
// downgrade,
// cancellation,
// newPost,
// commentReply,
// chatMessage,
class NotificationTypes {
  static const String liked = "liked";
  static const String commented = "commented";
  static const String newMember = "newMember";
  static const String downgrade = "downgrade";
  static const String cancellation = "cancellation";
  static const String newPost = "newPost";
  static const String commentReply = "commentReply";
  static const String chatMessage = "chatMessage";

  static List<String> get values => [liked, commented, newMember, downgrade, cancellation, newPost, commentReply, chatMessage];
}

class PostStatus {
  static const String draft = "draft";
  static const String published = "published";
  static const String archived = "archived";

  static List<String> get values => [draft, published, archived];
}

class MySharedPreferenceVariables {
  static String isFirst = "isfirst";
  static String lastOpenedTime = "last_opened_time";
  static String darkThemeModeEnabled = "darkThemeModeEnabled";
  static String isUserLoggedIn = "isUserLoggedIn";
  static String lastAppUpdateCheckedDate = "lastAppUpdateCheckedDate";
  static String isNavigateToBrowserScreen = "isNavigateToBrowserScreen";
  static String latestNotificationId = "latestNotificationId";
  static String loginSessionId = "loginSessionId";
  static String lastSharePromptShownKey = "lastSharePromptKey";
  static String username = "username";
  static String nickname = "nickname";
  static String userId = "user_id";
  static String isCreatorMode = "is_creator_mode";
  static String currentUserId = "current_user_id";

  // Sucurity related keys
  static String authToken = "authToken";
  static const pinKey = "user_app_pin";
  static const duressPinKey = "duress_pin";
  static const biometricKey = "biometric_enabled";
}