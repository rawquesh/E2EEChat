import 'package:e2ee_android_app/backend/user/user_repository.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';

import '../authentication/authentication_provider.dart';

class MyUserController {
  late UserRepository _userRepository;
  late AuthenticationProvider _authenticationProvider;

  MyUserController({UserRepository? repository, AuthenticationProvider? authenticationProvider}) {
    _userRepository = repository ?? UserRepository();
    _authenticationProvider = authenticationProvider ?? AuthenticationProvider();
  }

  Future<bool> updateDisplayName(String name) async {
    final token = await SharedPrefManager().getString(MySharedPreferenceVariables.authToken);
    if (token == null || token.isEmpty) return false;

    final success = await _userRepository.updateDisplayName(token: token, name: name);
    if (success) {
      await SharedPrefManager().setString(MySharedPreferenceVariables.nickname, name);
      MyPrint.printOnConsole('New nickname saved: $name');

      final user = _authenticationProvider.userModel.get();
      if (user != null) {
        user.displayName = name;
        _authenticationProvider.userModel.set(value: user, isNotify: true);
      }
    }
    return success;
  }
}
