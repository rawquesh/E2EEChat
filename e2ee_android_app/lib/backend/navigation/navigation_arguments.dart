import 'package:e2ee_models_app/backend/navigation/navigation_arguments.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';

import '../../views/authentication/screens/pin_entry_screen.dart';

class SignUpScreenNavigationArguments extends NavigationArguments {
  final UserModel userModel;

  const SignUpScreenNavigationArguments({
    required this.userModel,
  });
}

class PinEntryScreenNavigationArguments {
  final PinScreenMode mode;

  PinEntryScreenNavigationArguments({
    required this.mode,
  });
}
