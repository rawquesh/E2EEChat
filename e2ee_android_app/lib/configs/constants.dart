

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

  static List<String> get values => [
    male,
    female,
    both,
  ];
}

class Gender {
  static const String male = "male";
  static const String female = "female";
  static const String other = "other";

  static List<String> get values => [
    male,
    female,
    other,
  ];
}

// {
// label: "Show Both Male and Female",
// value: GenderPreference.BOTH,
// },
// { label: "Show Male Only", value: GenderPreference.MALE },
// {
// label: "Show Female Only",
// value: GenderPreference.FEMALE,
// },

class AppTypes {
  static const String user = "user";
  static const String admin = "admin";
  static const String withdraw = "withdraw";
}

class DiscountApplicableTo  {
  static const String all  = "all" ;
  static const String selected  = "selected";
}


class AppFlavors {
  static const String development = "development";
  static const String production = "production";
}

class AppAssets {
  //folders
  static const String onboardingFolder = 'assets/onboarding';
  static const String imagesFolder = 'assets/images';
  static const String iconsFolder = 'assets/icons';
  static const String lottiesFolder = 'assets/lotties';

  //onboarding
  static const String onBoardingSubImage1 = '$onboardingFolder/onboard_sub_1.png';
  static const String onBoardingSubImage2 = '$onboardingFolder/onboard_sub_2.png';
  static const String onBoardingSubImage3 = '$onboardingFolder/onboard_sub_3.png';
  static const String onBoardingNextButton = '$onboardingFolder/onboarding_next_button.png';

  //images
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

  //icons
  static const String share_icon_1 = '$iconsFolder/share_icon_1.png';
  static const String streak_icon = '$iconsFolder/streak_icon.png';

  // lotties
  static const String scanLotties = '$lottiesFolder/scan.json';
}


String commonUrl = "https://picsum.photos/400/400";

String imageTypeChat = "type=image;path,";
String videoTypeChat = "type=video;path,";
String audioTypeChat = "type=audio;path,";
String docTypeChat = "type=doc;path,";

