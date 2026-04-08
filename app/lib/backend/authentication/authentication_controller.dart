import 'package:e2ee_android_app/navigation/navigation_arguments.dart';
import 'dart:io';

import 'package:e2ee_android_app/backend/chats/chat_repository.dart';
import 'package:e2ee_android_app/backend/notification/notification_service.dart';
import 'package:e2ee_android_app/backend/user/my_user_controller.dart';
import 'package:e2ee_android_app/backend/user/user_repository.dart';
import 'package:e2ee_android_app/helpers/encryption_helper.dart';
import 'package:e2ee_android_app/constants/app_constants.dart';
import 'package:e2ee_android_app/navigation/navigation_operation_parameters.dart';
import 'package:e2ee_android_app/navigation/navigation_type.dart';
import 'package:e2ee_android_app/models/chats/chat_message_model.dart';
import 'package:e2ee_android_app/models/chats/chat_user_model.dart';
import 'package:e2ee_android_app/models/user/user_model.dart';
import 'package:e2ee_android_app/managers/hive_manager.dart';
import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:e2ee_android_app/utils/my_toast.dart';
import 'package:e2ee_android_app/utils/my_utils.dart';
import 'package:e2ee_android_app/managers/secure_storage_manager.dart';
import 'package:e2ee_android_app/managers/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';

import '../navigation/navigation_controller.dart';
import 'authentication_provider.dart';
import 'authentication_repository.dart';

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

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async => await _auth.canCheckBiometrics;

  Future<bool> enableBiometric(bool enable) async {
    await SecureStorageManager().setString(MySharedPreferenceVariables.biometricKey, enable ? "true" : "false");
    return enable;
  }

  Future<bool> isBiometricEnabled() async {
    final val = await SecureStorageManager().getString(MySharedPreferenceVariables.biometricKey);
    return val == "true";
  }

  Future<bool> authenticateWithBiometric() async {
    if (!await isBiometricEnabled()) return false;
    return await _auth.authenticate(
      localizedReason: "Unlock with fingerprint or Face ID",
      options: const AuthenticationOptions(biometricOnly: true),
    );
  }

  // Future<bool> signUpWithUsernamePassword(BuildContext context, String username, String password) async {
  //   try {
  //     MyPrint.printOnConsole("Generating keys...");
  //     final keyBundle = await KeyManager.generateAndStoreKeys();

  //     MyPrint.printOnConsole("Building registration payload...");
  //     Map<String, dynamic> payload = {
  //       "username": username,
  //       "password": password,
  //       "publicKey": keyBundle['publicKey'],
  //       "identityKey": keyBundle['identityKey'],
  //     };

  //     MyPrint.printOnConsole("Payload: $payload");

  //     MyPrint.printOnConsole("Sending registration request...");
  //     final result = await _authenticationRepository.registerNewUserFromPayload(payload);

  //     final accessToken = result?['data']?['access_token'];

  //     if (result != null && accessToken != null && accessToken.isNotEmpty) {
  //       MyPrint.printOnConsole("Saving auth token: $accessToken");
  //       await SecureStorageManager().setString(MySharedPreferenceVariables.authToken, accessToken);

  //       await _authenticationRepository.uploadKeyBundle(token: accessToken, keyBundle: keyBundle);

  //       // Save current user id here!
  //       await saveCurrentUserId(username: username, accessToken: accessToken);

  //       MyPrint.printOnConsole("Registration successful");
  //       MyToast.showSuccess(context: context, msg: "Registration successful!");
  //       NavigationController.navigateToPinEntryScreen(
  //         navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamedAndRemoveUntil),
  //         arguments: PinEntryScreenNavigationArguments(mode: PinScreenMode.set),
  //       );
  //       return true;
  //     } else {
  //       MyPrint.printOnConsole("Registration failed");
  //       String errorMsg = result?['message'] ?? "Registration failed. Please try again.";
  //       MyToast.showError(context: context, msg: errorMsg);
  //       return false;
  //     }
  //   } catch (e) {
  //     MyPrint.printOnConsole('Error in signUpWithUsernamePassword: $e');
  //     MyToast.showError(context: context, msg: "An error occurred during registration. Please try again.");
  //     return false;
  //   }
  // }

  Future<void> _handleNicknameUpdate(BuildContext context, AuthenticationProvider authenticationProvider) async {
    try {
      // 1. Show the dialog and wait for the user to enter a nickname.
      final String? nickname = await _promptForNickname(context);

      // 2. If a nickname was provided, proceed to update it.
      if (nickname != null && nickname.isNotEmpty) {
        // 3. Initialize the controller.
        final userController = MyUserController(repository: UserRepository(), authenticationProvider: authenticationProvider);

        // 4. Call the update method.
        final success = await userController.updateDisplayName(nickname);

        // 5. Show feedback to the user.
        if (success) {
          MyToast.showSuccess(context: context, msg: 'Nickname saved!');
        } else {
          MyToast.showError(context: context, msg: 'Could not save nickname. You can set it later in settings.');
        }
      }
    } catch (e) {
      // Handle any potential errors during the nickname update process.
      MyPrint.printOnConsole('Error during nickname update: $e');
      MyToast.showError(context: context, msg: 'An error occurred while saving your nickname.');
    }
  }

  Future<String?> _promptForNickname(BuildContext context) async {
    final TextEditingController nicknameController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Set Your Nickname'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nicknameController,
              decoration: const InputDecoration(hintText: "Enter a nickname"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nickname cannot be empty.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(nicknameController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _isNickNameAvailable(String accessToken, String username) async {
    final userInfo = await ChatRepository().fetchChatUser(username: username, token: accessToken);
    if (userInfo != null) {
      MyPrint.printOnConsole("User model retrieved: ${userInfo.toMap()}");
      SharedPrefManager().setString(MySharedPreferenceVariables.currentUserId, userInfo.id);

      NotificationService.login(userId: userInfo.id);

      if (userInfo.nickname.isNotEmpty) {
        SharedPrefManager().setString(MySharedPreferenceVariables.nickname, userInfo.nickname);

        return true;
      } else {
        MyPrint.printOnConsole("Nickname is not set.");
        return false;
      }
    } else {
      MyPrint.printOnConsole("Failed to retrieve user model from token.");
    }

    return false;
  }

  Future<bool> loginWithUsernamePassword(BuildContext context, String username, String password, {String? token}) async {
    try {
      MyPrint.printOnConsole("Generating keys for login...");

      final myPublicKeyPem = await SecureStorageManager().getString(MySharedPreferenceVariables.myPublicKey);

      MyPrint.printOnConsole("XXEN My public key: $myPublicKeyPem");

      Map<String, dynamic> payload = {
        "username": username,
        "password": password,
        "publicKey": myPublicKeyPem,
        "identityKey": "null",
      };

      if (token != null && token.isNotEmpty) {
        payload['token'] = token;
      }

      MyPrint.printOnConsole("Login payload: $payload");

      final result = (token != null && token.isNotEmpty)
          ? await _authenticationRepository.registerNewUserFromPayloadWithToken(payload)
          : await _authenticationRepository.registerNewUserFromPayload(payload);

      final accessToken = result?['data']?['access_token'];

      MyPrint.printOnConsole("Login result: $result");

      if (result != null && accessToken != null && accessToken.isNotEmpty) {
        await SecureStorageManager().setString(MySharedPreferenceVariables.authToken, accessToken);

        if (!(await _isNickNameAvailable(accessToken, username))) {
          await _handleNicknameUpdate(context, authenticationProvider);
        }

        NavigationController.navigateToPinEntryScreen(
          navigationOperationParameters: NavigationOperationParameters(
            context: context,
            navigationType: NavigationType.pushNamedAndRemoveUntil,
          ),
          arguments: PinEntryScreenNavigationArguments(mode: PinScreenMode.set),
        );
        SharedPrefManager().setString(MySharedPreferenceVariables.username, username);
        MyPrint.printOnConsole("Username saved: $username");

        String successMsg = result['message'] ?? "Login Successful.";
        MyToast.showSuccess(context: context, msg: successMsg);
        return true;
      } else {
        MyPrint.printOnConsole("result data: ${result}");
        String errorMsg = result?['message'] ?? "Login ffailed. Please try again.";
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
    final storedPin = await SecureStorageManager().getString(MySharedPreferenceVariables.pinKey);
    return storedPin != null && storedPin.isNotEmpty;
  }

  Future<bool> setNewPin(String pin, String confirmPin, {bool isVaultPin = false}) async {
    try {
      // Validate PIN length
      if (pin.length != 4) {
        return false;
      }

      // Check if PINs match
      if (pin != confirmPin) {
        return false;
      }

      // Save the PIN securely
      await SecureStorageManager().setString(
        isVaultPin ? MySharedPreferenceVariables.mediaPinKey : MySharedPreferenceVariables.pinKey,
        pin,
      );

      MyPrint.printOnConsole("PIN saved successfully");
      return true;
    } catch (e) {
      MyPrint.printOnConsole("Error saving PIN: $e");
      return false;
    }
  }

  Future<bool> setNewDuressPin(String pin, String confirmPin, BuildContext context) async {
    try {
      final storedPin = await SecureStorageManager().getString(MySharedPreferenceVariables.pinKey);
      if (pin == storedPin) {
        MyToast.showError(context: context, msg: "Duress PIN cannot be the same as the main PIN.");
        return false;
      }
      if (pin.length != 4 || pin != confirmPin) {
        return false;
      }
      await SecureStorageManager().setString(MySharedPreferenceVariables.duressPinKey, pin);
      MyPrint.printOnConsole("Duress PIN saved successfully");
      return true;
    } catch (e) {
      MyPrint.printOnConsole("Error saving Duress PIN: $e");
      return false;
    }
  }

  Future<bool> verifyPin(String pin, {bool isVaultPin = false}) async {
    final storedPin = await SecureStorageManager().getString(
      isVaultPin ? MySharedPreferenceVariables.mediaPinKey : MySharedPreferenceVariables.pinKey,
    );
    final storedDuressPin = await SecureStorageManager().getString(MySharedPreferenceVariables.duressPinKey);

    MyPrint.printOnConsole("XX Verifying current PIN: $pin");
    MyPrint.printOnConsole("XX Stored PIN: $storedPin");
    MyPrint.printOnConsole("XX Stored Duress PIN: $storedDuressPin");

    return pin == storedPin;
  }

  Future<bool> verifyDuressPin(String pin) async {
    final storedDuressPin = await SecureStorageManager().getString(MySharedPreferenceVariables.duressPinKey);

    if (storedDuressPin != null && pin == storedDuressPin) {
      await wipeAllAuthData();
      return false; // Indicate duress mode
    }

    return pin == storedDuressPin;
  }

  // Future<void> saveCurrentUserId({required String username, required String accessToken}) async {
  //   final chatUser = await ChatRepository().fetchChatUser(username: username, token: accessToken);

  //   if (chatUser != null && chatUser.id.isNotEmpty) {
  //     await SharedPrefManager().setString(MySharedPreferenceVariables.currentUserId, chatUser.id);
  //     MyPrint.printOnConsole('[DEBUG] Saved current user id: ${chatUser.id}');
  //   } else {
  //     MyPrint.printOnConsole('[ERROR] Could not fetch or save user id!');
  //   }
  // }

  Future<void> wipeAllAuthData() async {
    await SecureStorageManager().delete(key: MySharedPreferenceVariables.pinKey);
    await SecureStorageManager().delete(key: MySharedPreferenceVariables.biometricKey);
    await SecureStorageManager().delete(key: MySharedPreferenceVariables.mediaPinKey);

    NotificationService.logut();

    //start code for delete all chat data
    Box? box = await HiveManager().openBox(boxName: "chat_users");
    if (box != null) {
      for (final entry in box.toMap().entries) {
        try {
          final user = ChatUserModel.fromMap(Map<String, dynamic>.from(entry.value));
          final messageBox = await Hive.openBox("messages_${user.id}");
          for (final messageEntry in messageBox.toMap().entries) {
            final message = ChatMessageModel.fromMap(Map<String, dynamic>.from(messageEntry.value), currentUserId: '');
            if (message.message.base64String.isNotEmpty) {
              final filePath = message.message.base64String;
              final file = File(filePath);
              if (await file.exists()) {
                await file.delete();
              }
            }
          }
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
    final directory = await getApplicationDocumentsDirectory();
    final vaultDirectory = Directory('${directory.path}/vault');
    if (await vaultDirectory.exists()) {
      await vaultDirectory.delete(recursive: true);
    }
    await SecureStorageManager().deleteAll();
    await SharedPrefManager().clearAll();

    await EncryptionHelper().init();
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

    authenticationProvider.userModel.set(value: userModel, isNotify: true);

    authenticationProvider.userId.set(value: userModel.userId, isNotify: false);
    authenticationProvider.email.set(value: userModel.email, isNotify: false);

    String notificationToken = MyUtils.getNewId();
    await SecureStorageManager().setString(MySharedPreferenceVariables.authToken, _authToken ?? "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.userId, userModel.userId);
    await SharedPrefManager().setString(MySharedPreferenceVariables.loginSessionId, notificationToken);
    authenticationProvider.loginSessionId.set(value: notificationToken, isNotify: false);

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
          navigationOperationParameters: NavigationOperationParameters(
            context: context,
            navigationType: NavigationType.pushNamedAndRemoveUntil,
          ),
          arguments: SignUpScreenNavigationArguments(userModel: userModel),
        );
        return;
      } else {
        // Existing user, navigate to main screen
        MyPrint.printOnConsole("Existing Google user, navigating to main screen");
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

  Future<bool> checkUserWithIdExistOrNotAndIfNotExistThenCreate({
    required String userId,
    String? authenticationMode,
    required String email,
  }) async {
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
      MyPrint.printOnConsole(s.toString());
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
    await SecureStorageManager().setString(MySharedPreferenceVariables.authToken, "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.userId, "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.currentUserId, "");
    await SharedPrefManager().setString(MySharedPreferenceVariables.loginSessionId, "");
    await SharedPrefManager().setBool(MySharedPreferenceVariables.isCreatorMode, false);

    authenticationProvider.resetData(isNotify: true);

    return true;
  }
}
