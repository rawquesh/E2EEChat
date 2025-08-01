import 'dart:io';

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
    final token = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken);
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

  Future<bool> updateProfile({String? name, File? profilePhoto}) async {
    final token = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken);
    if (token == null || token.isEmpty) return false;

    final result = await _userRepository.updateProfile(token: token, name: name, profilePhoto: profilePhoto);

    if (result != null) {
      if (name != null && name.isNotEmpty) {
        await SharedPrefManager().setString(MySharedPreferenceVariables.nickname, name);
        MyPrint.printOnConsole('New nickname saved: $name');
        final user = _authenticationProvider.userModel.get();
        if (user != null) {
          user.displayName = name;
          _authenticationProvider.userModel.set(value: user, isNotify: true);
        }
      }

      final newAvatarUrl = result['data']?['avatar_url'];
      if (newAvatarUrl != null) {
        await SharedPrefManager().setString('profile_pic_url', newAvatarUrl);
        MyPrint.printOnConsole('New avatar URL saved: $newAvatarUrl');
      }

      return true;
    }
    return false;
  }
}
