import 'dart:io';

import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';

import '../authentication/authentication_provider.dart';

class MyUserController {
  // late UserRepository _userRepository;
  late AuthenticationProvider _authenticationProvider;

  MyUserController({
    // UserRepository? repository,
    AuthenticationProvider? authenticationProvider,
  }) {
    // _userRepository = repository ?? UserRepository();
    _authenticationProvider =
        authenticationProvider ?? AuthenticationProvider();
  }


  /*Future<String?> uploadCoverImage({required File imageFile}) async {
    final tag = 'uploadCoverImage';
    try {
      String? token = await SharedPrefManager()
          .getString(MySharedPreferenceVariables.authToken);
      final url = await _userRepository.uploadProfileCover(
        token: token,
        imageFile: imageFile,
      );
      if (url != null && url.isNotEmpty) {
        final userModel = _authenticationProvider.userModel.get();
        if (userModel != null) {
          userModel.profileCover = url;
          _authenticationProvider.userModel.set(value: userModel, isNotify: true);
        }
      }
      return url;
    } catch (e) {
      MyPrint.printOnConsole('Error uploading cover image: $e', tag: tag);
      return null;
    }
  }

  Future<String?> uploadProfileImage({required File imageFile}) async {
    final tag = 'uploadProfileImage';
    try {
      String? token = await SharedPrefManager()
          .getString(MySharedPreferenceVariables.authToken);
      final url = await _userRepository.uploadProfilePhoto(
        token: token,
        imageFile: imageFile,
      );
      if (url != null && url.isNotEmpty) {
        final userModel = _authenticationProvider.userModel.get();
        if (userModel != null) {
          userModel.profilePicture = url;
          _authenticationProvider.userModel.set(value: userModel, isNotify: true);
        }
      }
      return url;
    } catch (e) {
      MyPrint.printOnConsole('Error uploading profile image: $e', tag: tag);
      return null;
    }
  }

  Future<bool> updateCreatorHeadline({required String headline}) async {
    try {
      final token = await SharedPrefManager().getString(MySharedPreferenceVariables.authToken);
      final updatedUser = await _userRepository.updateCreatorHeadline(token: token, headline: headline);

      if (updatedUser != null) {
        _authenticationProvider.userModel.set(value: updatedUser, isNotify: true);
        return true;
      }
    } catch (e) {
      MyPrint.printOnConsole("Exception in updateCreatorHeadline: $e");
    }
    return false;
  }*/
}