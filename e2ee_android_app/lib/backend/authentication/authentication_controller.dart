import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';
import 'package:e2ee_models_app/utils/extensions.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:flutter/material.dart';

import '../navigation/navigation_arguments.dart';
import '../navigation/navigation_controller.dart';
import 'authentication_provider.dart';
import 'authentication_repository.dart';

class AuthenticationController {
  late AuthenticationProvider _authenticationProvider;
  late AuthenticationRepository _authenticationRepository;
  String? _authToken;

  AuthenticationController({
    required AuthenticationProvider? authenticationProvider,
    AuthenticationRepository? repository,
  }) {
    _authenticationProvider =
        authenticationProvider ?? AuthenticationProvider();
    _authenticationRepository = repository ?? AuthenticationRepository();
  }

  AuthenticationProvider get authenticationProvider => _authenticationProvider;

  AuthenticationRepository get authenticationRepository =>
      _authenticationRepository;

  Future<bool> signInWithGoogle({required BuildContext context}) async {
    try {
      final result = await _authenticationRepository.signInWithGoogle(context: context);

      // Validate result and userData structure
      if (result is! Map<String, dynamic> || result['userData'] is! Map<String, dynamic>) {
        MyPrint.printOnConsole('Sign in failed: Invalid or missing user data');
        return false;
      }

      _authToken = result['token'];

      final UserModel? userModel = await _authenticationRepository.getUserFromToken(_authToken!);
      if (userModel == null) {
        MyPrint.printOnConsole('Sign in failed: Could not fetch user model from token');
        return false;
      }


      MyPrint.printOnConsole('User Data from google sign in: ${userModel.toMap()}');

      _authenticationProvider.userId.set(value: userModel.userId, isNotify: false);
      _authenticationProvider.email.set(value: userModel.email, isNotify: false);
      _authenticationProvider.userModel.set(value: userModel, isNotify: true);

      await SharedPrefManager().setString(MySharedPreferenceVariables.userId, userModel.userId);
      await SharedPrefManager().setString(MySharedPreferenceVariables.authToken, _authToken ?? "");

      await onLoginSuccess(
        context: context,
        userModel: userModel,
        authenticationMode: AuthenticationModes.google,
      );

      return true;
    } catch (e) {
      MyPrint.printOnConsole('Sign in error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _authenticationRepository.signInWithEmail(
        email: email,
        password: password,
      );

      if (result == null) return null;

      _authToken = result['token'];
      UserModel? userModel;

      if (_authToken != null && _authToken!.isNotEmpty) {
        userModel = await _authenticationRepository.getUserFromToken(_authToken!);
        MyPrint.printOnConsole(
            "Fetched user model using token: ${userModel?.toMap()}");
      }

      if (userModel == null) {
        final userData = result['userData'];
        if (userData == null) return null;

        userModel = UserModel(
          userId: userData['id'] ?? "",
          firstName: userData['firstName'] ?? "",
          lastName: userData['lastName'] ?? "",
          email: userData['email'] ?? "",
          displayName:
          "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"
              .trim(),
          profilePicture: userData["profilePicture"] ?? "",
          authenticationMode: AuthenticationModes.email,
        );
      }

      _authenticationProvider.userId
          .set(value: userModel.userId, isNotify: false);
      _authenticationProvider.email
          .set(value: userModel.email, isNotify: false);
      _authenticationProvider.userModel.set(value: userModel, isNotify: true);

      // 🔍 Print the stored userModel
      MyPrint.printOnConsole(
          "UserModel set in provider: ${userModel.toString()}");

      await SharedPrefManager()
          .setString(MySharedPreferenceVariables.userId, userModel.userId);
      await SharedPrefManager()
          .setString(MySharedPreferenceVariables.authToken, _authToken ?? "");

      return {
        'token': _authToken,
        'userModel': userModel,
      };
    } catch (e) {
      MyPrint.printOnConsole('Email sign in error: $e');
      return null;
    }
  }

  Future<bool> isUserLoggedIn() async {
    String? token = await SharedPrefManager()
        .getString(MySharedPreferenceVariables.authToken);
    String? userId =
        await SharedPrefManager().getString(MySharedPreferenceVariables.userId);

    MyPrint.printOnConsole("Retrieved authToken: $token");
    MyPrint.printOnConsole("Retrieved userId: $userId");

    MyPrint.printOnConsole(
        'Checking login status - token: ${token != null}, userId: $userId');

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      MyPrint.printOnConsole('No saved credentials found');
      return false;
    }

    try {
      UserModel? userModel =
          await _authenticationRepository.getUserFromToken(token);

      if (userModel != null) {
        MyPrint.printOnConsole('Retrieved user model from token');

        MyPrint.logOnConsole("userModel: ${userModel}");
        _authenticationProvider.userId
            .set(value: userModel.userId, isNotify: false);
        _authenticationProvider.email
            .set(value: userModel.email, isNotify: false);
        _authenticationProvider.userModel.set(value: userModel, isNotify: true);
        _authToken = token;

        String notificationToken = await SharedPrefManager()
                .getString(MySharedPreferenceVariables.loginSessionId) ??
            MyUtils.getNewId();
        await SharedPrefManager().setString(
            MySharedPreferenceVariables.loginSessionId, notificationToken);
        _authenticationProvider.loginSessionId
            .set(value: notificationToken, isNotify: false);

        return true;
      }

      MyPrint.printOnConsole('User model not found from token, logging out');
      await logout(isNavigateToLogin: false);
      return false;
    } catch (e) {
      MyPrint.printOnConsole('Error retrieving user from token: $e');
      return false;
    }
  }

  Future<void> onLoginSuccess({
    required BuildContext context,
    required UserModel userModel,
    String authenticationMode = "",
  }) async {
    MyPrint.printOnConsole("called onLoginSuccess");

    if (userModel.email.isEmpty) {
      await logout(isNavigateToLogin: true);
      return;
    }

    authenticationProvider.userModel.set(
      value: userModel,
      isNotify: true,
    );

    authenticationProvider.userId.set(
      value: userModel.userId,
      isNotify: false,
    );
    authenticationProvider.email.set(
      value: userModel.email,
      isNotify: false,
    );

    String notificationToken = MyUtils.getNewId();
    await SharedPrefManager().setString(
      MySharedPreferenceVariables.authToken,
      _authToken ?? "",
    );
    await SharedPrefManager().setString(
      MySharedPreferenceVariables.userId,
      userModel.userId,
    );
    await SharedPrefManager().setString(
      MySharedPreferenceVariables.loginSessionId,
      notificationToken,
    );
    authenticationProvider.loginSessionId.set(
      value: notificationToken,
      isNotify: false,
    );

    if (context.checkMounted() && context.mounted) {
      if (authenticationMode == AuthenticationModes.google) {
        bool isUserExist =
            await checkUserWithIdExistOrNotAndIfNotExistThenCreate(
          userId: userModel.userId,
          authenticationMode: authenticationMode,
          email: userModel.email,
        );

        if (!isUserExist) {
          // New user, navigate to sign-up
          MyPrint.printOnConsole("New Google user, navigating to sign-up");
          await NavigationController.navigateToSignUpScreen(
            navigationOperationParameters: NavigationOperationParameters(
              context: context,
              navigationType: NavigationType.pushNamedAndRemoveUntil,
            ),
            arguments: SignUpScreenNavigationArguments(userModel: userModel),
          );
          return;
        } else {
          // Existing user, navigate to main screen
          MyPrint.printOnConsole(
              "Existing Google user, navigating to main screen");
          NavigationController.navigateToMainScreen(
            navigationOperationParameters: NavigationOperationParameters(
              context: context,
              navigationType: NavigationType.pushNamedAndRemoveUntil,
            ),
          );
          return;
        }
      }

      // For non-Google authentication
      NavigationController.navigateToMainScreen(
        navigationOperationParameters: NavigationOperationParameters(
          context: context,
          navigationType: NavigationType.pushNamedAndRemoveUntil,
        ),
      );
    }
  }

  Future<bool> checkUserWithIdExistOrNotAndIfNotExistThenCreate({
    required String userId,
    String? authenticationMode,
    required String email,
  }) async {
    if (userId.isEmpty || email.isEmpty) return false;

    try {
      // Check if the email is already in use
      final emailCheckResult =
          await _authenticationRepository.checkEmailExists(email);

      if (emailCheckResult == null) {
        MyPrint.printOnConsole("Failed to check email existence");
        return false;
      }

      final bool isInUse = emailCheckResult['isInUse'] ?? false;

      if (isInUse) {
        // User exists, mark as existing but don't retrieve detailed data
        return true;
      } else {
        // User does not exist, create new user
        UserModel createdUserModel = UserModel(
          userId: userId,
          mobileNumber: authenticationProvider.mobileNumber.get(),
          email: email,
          authenticationMode: authenticationMode ?? AuthenticationModes.google,
          firstName: "",
          lastName: "",
        );

        final Map<String, dynamic>? isRegistered =
            await _authenticationRepository.registerNewUser(createdUserModel);
        if (isRegistered != null) {
          authenticationProvider.userModel
              .set(value: createdUserModel, isNotify: false);
        }
        return false;
      }
    } catch (e, s) {
      MyPrint.printOnConsole("Error: $e");
      MyPrint.printOnConsole(s);
      return false;
    }
  }

  Future<bool> logout({
    bool isShowConfirmationDialog = false,
    bool isNavigateToLogin = false,
    bool isForceLogout = false,
    String forceLogoutMessage = "",
  }) async {
    MyPrint.printOnConsole("AuthenticationController().logout() called");

    await _authenticationRepository.signOut();
    _authToken = null;

    // Clears stored credentials from SharedPreferences
    await SharedPrefManager()
        .setString(MySharedPreferenceVariables.authToken, "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.userId, "");
    await SharedPrefManager()
        .setString(MySharedPreferenceVariables.loginSessionId, "");
    await SharedPrefManager().setBool(MySharedPreferenceVariables.isCreatorMode, false);

    authenticationProvider.resetData(isNotify: true);

    return true;
  }
}
