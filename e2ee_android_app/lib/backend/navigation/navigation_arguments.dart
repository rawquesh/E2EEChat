import 'package:e2ee_models_app/backend/navigation/navigation_arguments.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';

class SignUpScreenNavigationArguments extends NavigationArguments {
  final UserModel userModel;

  const SignUpScreenNavigationArguments({
    required this.userModel,
  });
}
