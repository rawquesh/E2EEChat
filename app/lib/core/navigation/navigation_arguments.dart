import '../../models/chats/chat_user_model.dart';
import '../../models/user/user_model.dart';
import '../../utils/enums.dart';

class NavigationArguments {
  const NavigationArguments();
}

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
