// Merged: combines constants from both apps

const double verticalPadding = 8;
const double horizontalPadding = 16;
const double circularRadius = 12;

const List<String> categories = [
  'Music & Art',
  'Entertainment & Comedy',
  'Travel & Israel',
  'General Education',
  'Business & Finance',
  'Lifestyle & Wellness',
  'Torah Study',
  'History & Literacy',
  'Food & Cooking',
];

class ContentVisibilityTypes {
  static const String male = "male";
  static const String female = "female";
  static const String both = "both";
  static List<String> get values => [male, female, both];
}

class Gender {
  static const String male = "male";
  static const String female = "female";
  static const String other = "other";
  static List<String> get values => [male, female, other];
}

class AppTypes {
  static const String user = "user";
  static const String admin = "admin";
  static const String withdraw = "withdraw";
}

class DiscountApplicableTo {
  static const String all = "all";
  static const String selected = "selected";
}

class AppFlavors {
  static const String development = "development";
  static const String production = "production";
}

class AppAssets {
  static const String onboardingFolder = 'assets/onboarding';
  static const String imagesFolder = 'assets/images';
  static const String iconsFolder = 'assets/icons';
  static const String lottiesFolder = 'assets/lotties';

  static const String onBoardingSubImage1 = '$onboardingFolder/onboard_sub_1.png';
  static const String onBoardingSubImage2 = '$onboardingFolder/onboard_sub_2.png';
  static const String onBoardingSubImage3 = '$onboardingFolder/onboard_sub_3.png';
  static const String onBoardingNextButton = '$onboardingFolder/onboarding_next_button.png';

  static const String loginHeader = '$imagesFolder/login_header.png';
  static const String otpHeader = '$imagesFolder/otp_header.png';
  static const String signupBanner = '$imagesFolder/signupBanner.png';
  static const String app_logo = '$imagesFolder/logo_foreground.png';
  static const String male = '$imagesFolder/male.png';
  static const String community_policy_icon = '$imagesFolder/community_policy_icon.png';
  static const String feature_request_icon = '$imagesFolder/feature_request_icon.png';
  static const String helpcenter_faq_icon = '$imagesFolder/helpcenter_faq_icon.png';
  static const String news_icon = '$imagesFolder/news_icon.png';
  static const String terms_of_service_icon = '$imagesFolder/terms_of_service_icon.png';
  static const String privacy_policy_icon = '$imagesFolder/privacy_policy_icon.png';
  static const String logout_icon = '$imagesFolder/logout_icon.png';
  static const String membership_icon = '$imagesFolder/membership_icon.png';
  static const String create = '$imagesFolder/create.png';
  static const String bg_image = '$imagesFolder/bg_image.png';
  static const String more_icon = '$imagesFolder/more_icon.png';
  static const String share_icon = '$imagesFolder/share_icon.png';
  static const String add_icon = '$imagesFolder/add_icon.png';
  static const String call_icon = '$imagesFolder/call_icon.png';
  static const String chat_icon = '$imagesFolder/chat_icon.png';
  static const String files_icon = '$imagesFolder/files_icon.png';
  static const String settings_icon = '$imagesFolder/settings_icon.png';

  static const String share_icon_1 = '$iconsFolder/share_icon_1.png';
  static const String streak_icon = '$iconsFolder/streak_icon.png';

  static const String scanLotties = '$lottiesFolder/scan.json';
}

String commonUrl = "https://picsum.photos/400/400";

enum ChatMessageType { Text, Image, Video, Audio, Doc }

enum LoginType { basic, withToken }

const LoginType currentLoginType = LoginType.withToken;

// From models_app/constants.dart
class SharedPreferenceVariables {
  static const String darkThemeModeEnabled = "darkThemeModeEnabled";
  static const String isUserLoggedIn = "isUserLoggedIn";
}

class ApiUrls {
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
  static String avatarUrl = "avatar_url";

  static String batteryOptimizationRequested = "battery_optimization_requested";

  // Security related keys
  static String authToken = "authToken";
  static String myPublicKey = "my_rsa_public_key";
  static String myPrivateKey = "my_rsa_private_key";

  static String getPublicKeyPath(String userId) {
    return "rsa_public_key_$userId";
  }

  static const String pinKey = "user_app_pin";
  static const String duressPinKey = "duress_pin";
  static const String biometricKey = "biometric_enabled";
  static const String mediaPinKey = "media_pin";
}
