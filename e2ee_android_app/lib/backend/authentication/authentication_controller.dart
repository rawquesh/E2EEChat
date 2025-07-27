import 'package:e2ee_android_app/backend/chats/chat_repository.dart';
import 'package:e2ee_models_app/backend/key_manager/key_manager.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';
import 'package:e2ee_models_app/utils/extensions.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_toast.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../views/authentication/screens/pin_entry_screen.dart';
import '../navigation/navigation_arguments.dart';
import '../navigation/navigation_controller.dart';
import 'authentication_provider.dart';
import 'authentication_repository.dart';
import 'package:hive/hive.dart';
import 'package:e2ee_models_app/utils/hive_manager.dart';


class AuthenticationController {
  late AuthenticationProvider _authenticationProvider;
  late AuthenticationRepository _authenticationRepository;
  String? _authToken;

  AuthenticationController({required AuthenticationProvider? authenticationProvider, AuthenticationRepository? repository}) {
    _authenticationProvider = authenticationProvider ?? AuthenticationProvider();
    _authenticationRepository = repository ?? AuthenticationRepository();
  }

  AuthenticationProvider get authenticationProvider => _authenticationProvider;

  AuthenticationRepository get authenticationRepository => _authenticationRepository;

  static final _storage = FlutterSecureStorage();
  static const _pinKey = "user_app_pin";
  static const _biometricKey = "biometric_enabled";

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async => await _auth.canCheckBiometrics;

  Future<bool> enableBiometric(bool enable) async {
    await _storage.write(key: _biometricKey, value: enable ? "true" : "false");
    return enable;
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricKey);
    return val == "true";
  }

  Future<bool> authenticateWithBiometric() async {
    if (!await isBiometricEnabled()) return false;
    return await _auth.authenticate(localizedReason: "Unlock with fingerprint or Face ID", options: const AuthenticationOptions(biometricOnly: true));
  }

  Future<bool> signUpWithUsernamePassword(BuildContext context, String username, String password) async {
    try {
      MyPrint.printOnConsole("Generating keys...");
      final keyBundle = await KeyManager.generateAndStoreKeys();

      MyPrint.printOnConsole("Building registration payload...");
      Map<String, dynamic> payload = {
        "username": username,
        "password": password,
        "publicKey": keyBundle['publicKey'],
        "identityKey": keyBundle['identityKey'],
      };

      MyPrint.printOnConsole("Payload: $payload");

      MyPrint.printOnConsole("Sending registration request...");
      final result = await _authenticationRepository. registerNewUserFromPayload(payload);

      final accessToken = result?['data']?['access_token'];

      if (result != null && accessToken != null && accessToken.isNotEmpty) {
        MyPrint.printOnConsole("Saving auth token: $accessToken");
        await SharedPrefManager().setString(MySharedPreferenceVariables.authToken, accessToken);

        await _authenticationRepository.uploadKeyBundle(token: accessToken, keyBundle: keyBundle);

        // Save current user id here!
        await saveCurrentUserId(username: username, accessToken: accessToken);

        MyPrint.printOnConsole("Registration successful");
        MyToast.showSuccess(context: context, msg: "Registration successful!");
        NavigationController.navigateToPinEntryScreen(
          navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamedAndRemoveUntil),
          arguments: PinEntryScreenNavigationArguments(mode: PinScreenMode.set),
        );
        return true;
      } else {
        MyPrint.printOnConsole("Registration failed");
        String errorMsg = result?['message'] ?? "Registration failed. Please try again.";
        MyToast.showError(context: context, msg: errorMsg);
        return false;
      }
    } catch (e) {
      MyPrint.printOnConsole('Error in signUpWithUsernamePassword: $e');
      MyToast.showError(context: context, msg: "An error occurred during registration. Please try again.");
      return false;
    }
  }

  Future<bool> loginWithUsernamePassword(BuildContext context, String username, String password) async {
    try {
      MyPrint.printOnConsole("Generating keys for login...");
      final keyBundle = await KeyManager.generateAndStoreKeys();

      Map<String, dynamic> payload = {
        "username": username,
        "password": password,
        "publicKey": keyBundle['publicKey'],
        "identityKey": keyBundle['identityKey'],
      };

      MyPrint.printOnConsole("Login payload: $payload");

      final result = await _authenticationRepository.registerNewUserFromPayload(payload);
      final accessToken = result?['data']?['access_token'];

      if (result != null && accessToken != null && accessToken.isNotEmpty) {
        await SharedPrefManager().setString(MySharedPreferenceVariables.authToken, accessToken);

        await _authenticationRepository.uploadKeyBundle(token: accessToken, keyBundle: keyBundle);

        // Save current user id here!
        await saveCurrentUserId(username: username, accessToken: accessToken);

        //  Edit Nickname logic here

        NavigationController.navigateToPinEntryScreen(
          navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamedAndRemoveUntil),
          arguments: PinEntryScreenNavigationArguments(mode: PinScreenMode.set),
        );
        SharedPrefManager().setString(MySharedPreferenceVariables.username, username);
        MyPrint.printOnConsole("Username saved: $username");

        String successMsg = result['message'] ?? "Login Successful.";
        MyToast.showSuccess(context: context, msg: successMsg);
        return true;
      } else {
        String errorMsg = result?['message'] ?? "Login failed. Please try again.";
        MyToast.showError(context: context, msg: errorMsg);
        return false;
      }
    } catch (e) {
      MyPrint.printOnConsole('Error in loginWithUsernamePassword: $e');
      MyToast.showError(context: context, msg: "An error occurred during login. Please try again.");
      return false;
    }
  }

  Future<bool> hasPin() async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin != null && storedPin.isNotEmpty;
  }

  Future<bool> setNewPin(String pin, String confirmPin) async {
    try {
      // Validate PIN length
      if (pin.length < 6 || pin.length > 8) {
        return false;
      }

      // Check if PINs match
      if (pin != confirmPin) {
        return false;
      }

      // Save the PIN securely
      await _storage.write(key: _pinKey, value: pin);

      MyPrint.printOnConsole("PIN saved successfully");
      return true;
    } catch (e) {
      MyPrint.printOnConsole("Error saving PIN: $e");
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return pin == storedPin;
  }

  Future<void> saveCurrentUserId({required String username, required String accessToken}) async {
    final chatUser = await ChatRepository().fetchChatUser(username: username, token: accessToken);
    if (chatUser != null && chatUser.id.isNotEmpty) {
      await SharedPrefManager().setString('current_user_id', chatUser.id);
      print('[DEBUG] Saved current user id: ${chatUser.id}');
    } else {
      print('[ERROR] Could not fetch or save user id!');
    }
  }

  Future<void> wipeAllAuthData() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricKey);

    //start code for delete all chat data
    Box? box = await HiveManager().openBox(boxName: "chat_users");
    if(box != null){
      for (final entry in box.toMap().entries) {
        try {
          final user = ChatUserModel.fromMap(Map<String, dynamic>.from(entry.value));
          final messageBox = await Hive.openBox("messages_${user.id}");
          await messageBox.clear();
          await messageBox.close();
          await box.delete(user.id);
          MyPrint.printOnConsole('User Chat delete successfully');
        } catch (e) {
          MyPrint.printOnConsole('Error parsing chat user: $e');
        }
      }
      await box.clear();
    }
    //end code for delete all chat data
    // TODO: user data, tokens, etc.
  }

  Future<bool> isUserLoggedIn() async {
    String? token = await SharedPrefManager().getString(MySharedPreferenceVariables.authToken);
    String? userId = await SharedPrefManager().getString(MySharedPreferenceVariables.userId);

    MyPrint.printOnConsole("Retrieved authToken: $token");
    MyPrint.printOnConsole("Retrieved userId: $userId");

    MyPrint.printOnConsole('Checking login status - token: ${token != null}, userId: $userId');

    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      MyPrint.printOnConsole('No saved credentials found');
      return false;
    }

    try {
      UserModel? userModel = await _authenticationRepository.getUserFromToken(token);

      if (userModel != null) {
        MyPrint.printOnConsole('Retrieved user model from token');

        MyPrint.logOnConsole("userModel: ${userModel}");
        _authenticationProvider.userId.set(value: userModel.userId, isNotify: false);
        _authenticationProvider.email.set(value: userModel.email, isNotify: false);
        _authenticationProvider.userModel.set(value: userModel, isNotify: true);
        _authToken = token;

        String notificationToken = await SharedPrefManager().getString(MySharedPreferenceVariables.loginSessionId) ?? MyUtils.getNewId();
        await SharedPrefManager().setString(MySharedPreferenceVariables.loginSessionId, notificationToken);
        _authenticationProvider.loginSessionId.set(value: notificationToken, isNotify: false);

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

  Future<void> onLoginSuccess({required BuildContext context, required UserModel userModel, String authenticationMode = ""}) async {
    MyPrint.printOnConsole("called onLoginSuccess");

    if (userModel.email.isEmpty) {
      await logout(isNavigateToLogin: true);
      return;
    }

    authenticationProvider.userModel.set(value: userModel, isNotify: true);

    authenticationProvider.userId.set(value: userModel.userId, isNotify: false);
    authenticationProvider.email.set(value: userModel.email, isNotify: false);

    String notificationToken = MyUtils.getNewId();
    await SharedPrefManager().setString(MySharedPreferenceVariables.authToken, _authToken ?? "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.userId, userModel.userId);
    await SharedPrefManager().setString(MySharedPreferenceVariables.loginSessionId, notificationToken);
    authenticationProvider.loginSessionId.set(value: notificationToken, isNotify: false);

    if (context.checkMounted() && context.mounted) {
      if (authenticationMode == AuthenticationModes.google) {
        bool isUserExist = await checkUserWithIdExistOrNotAndIfNotExistThenCreate(
          userId: userModel.userId,
          authenticationMode: authenticationMode,
          email: userModel.email,
        );

        if (!isUserExist) {
          // New user, navigate to sign-up
          MyPrint.printOnConsole("New Google user, navigating to sign-up");
          await NavigationController.navigateToSignUpScreen(
            navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamedAndRemoveUntil),
            arguments: SignUpScreenNavigationArguments(userModel: userModel),
          );
          return;
        } else {
          // Existing user, navigate to main screen
          MyPrint.printOnConsole("Existing Google user, navigating to main screen");
          NavigationController.navigateToMainScreen(
            navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamedAndRemoveUntil),
          );
          return;
        }
      }

      // For non-Google authentication
      NavigationController.navigateToMainScreen(
        navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamedAndRemoveUntil),
      );
    }
  }

  Future<bool> checkUserWithIdExistOrNotAndIfNotExistThenCreate({required String userId, String? authenticationMode, required String email}) async {
    if (userId.isEmpty || email.isEmpty) return false;

    try {
      // Check if the email is already in use
      final emailCheckResult = await _authenticationRepository.checkEmailExists(email);

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

        final Map<String, dynamic>? isRegistered = await _authenticationRepository.registerNewUser(createdUserModel);
        if (isRegistered != null) {
          authenticationProvider.userModel.set(value: createdUserModel, isNotify: false);
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
    await SharedPrefManager().setString(MySharedPreferenceVariables.authToken, "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.userId, "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.loginSessionId, "");
    await SharedPrefManager().setBool(MySharedPreferenceVariables.isCreatorMode, false);

    authenticationProvider.resetData(isNotify: true);

    return true;
  }
}
