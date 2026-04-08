// import 'package:e2ee_android_app/views/authentication/screens/sign_up_screen.dart';
import 'package:e2ee_android_app/configs/constants.dart';
import 'package:e2ee_android_app/core/my_safe_state.dart';
import 'package:e2ee_android_app/core/my_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../backend/authentication/authentication_controller.dart';
import '../../../backend/authentication/authentication_provider.dart';
import '../../../backend/authentication/auth_utils.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = "/LoginScreen";

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with MySafeState {
  static const double radius = 12;

  late AuthenticationController authenticationController;
  late AuthenticationProvider authenticationProvider;

  bool isLoading = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode tokenFocusNode = FocusNode();

  bool isUsernameEntered = false;
  bool isPasswordEntered = false;
  bool isTokenEntered = false;
  bool passwordVisible = false;
  bool isBiometricAvailable = true;
  int failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    authenticationProvider = context.read<AuthenticationProvider>();
    authenticationController = AuthenticationController(authenticationProvider: authenticationProvider);

    usernameController.addListener(_onUsernameChanged);
    passwordController.addListener(_onPasswordChanged);
    tokenController.addListener(_onTokenChanged);
    // _checkBiometricAvailability();
    _loadFailedAttempts();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    tokenController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    tokenFocusNode.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    setState(() {
      isUsernameEntered = usernameController.text.trim().isNotEmpty;
    });
  }

  void _onPasswordChanged() {
    setState(() {
      isPasswordEntered = passwordController.text.trim().isNotEmpty;
    });
  }

  void _onTokenChanged() {
    setState(() {
      isTokenEntered = tokenController.text.trim().isNotEmpty;
    });
  }

  Future<void> _loadFailedAttempts() async {
    try {
      failedAttempts = 0;
    } catch (e) {
      failedAttempts = 0;
    }
  }

  Future<void> _saveFailedAttempts() async {
    try {} catch (e) {
      // Handle error
    }
  }

  Future<void> _triggerDataWipe() async {
    await AuthUtils.handleUnauthorized(context: context, message: "Security breach detected. All data has been wiped.");
  }

  bool get isFormValid {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final token = tokenController.text.trim();
    final usernameValid = RegExp(r'^[a-z0-9]+$').hasMatch(username);

    if (currentLoginType == LoginType.withToken) {
      return username.isNotEmpty && password.length >= 6 && usernameValid && token.isNotEmpty;
    } else {
      return username.isNotEmpty && password.length >= 6 && usernameValid;
    }
  }

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final token = tokenController.text.trim();

    if (!RegExp(r'^[a-z0-9]+$').hasMatch(username)) {
      MyToast.showError(context: context, msg: "Username must be lowercase and alphanumeric.");
      return;
    }

    if (password.length < 6) {
      MyToast.showError(context: context, msg: "Password must be at least 6 characters.");
      return;
    }

    if (currentLoginType == LoginType.withToken && token.isEmpty) {
      MyToast.showError(context: context, msg: "Token is required.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await authenticationController.loginWithUsernamePassword(
        context,
        username,
        password,
        token: currentLoginType == LoginType.withToken ? token : null,
      );

      if (!success) {
        failedAttempts++;
        await _saveFailedAttempts();

        if (failedAttempts >= 5) {
          await _triggerDataWipe();
        }
      }
    } catch (e) {
      MyToast.showError(context: context, msg: "Login failed. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              Icon(Icons.security, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                "DarkCrypt Chat",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 32),
              TextField(
                controller: usernameController,
                focusNode: usernameFocusNode,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withAlpha(50),
                  labelText: "Username",
                  hintText: "e.g. john123",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                obscureText: !passwordVisible,
                textInputAction: TextInputAction.done,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withAlpha(50),
                  labelText: "Password",
                  hintText: "Enter your password",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[400]),
                    onPressed: () {
                      setState(() => passwordVisible = !passwordVisible);
                    },
                  ),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              if (currentLoginType == LoginType.withToken) const SizedBox(height: 20),
              if (currentLoginType == LoginType.withToken)
                TextField(
                  controller: tokenController,
                  focusNode: tokenFocusNode,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withAlpha(50),
                    labelText: "Token",
                    hintText: "Enter your token",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radius),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFormValid ? primaryColor : theme.disabledColor.withAlpha(75),
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                  ),
                  onPressed: isFormValid && !isLoading ? _login : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.login),
                  label: Text(isLoading ? "Please wait..." : "Authenticate"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
