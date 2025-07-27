import 'package:e2ee_android_app/utils/enums.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_arguments.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';


class SignUpScreenNavigationArguments extends NavigationArguments {
  final UserModel userModel;

  const SignUpScreenNavigationArguments({required this.userModel});
}

class PinEntryScreenNavigationArguments {
  final PinScreenMode mode;

  PinEntryScreenNavigationArguments({required this.mode});
}

class VoiceCallScreenNavigationArguments {
  final ChatUserModel user;

  VoiceCallScreenNavigationArguments({required this.user});
}
