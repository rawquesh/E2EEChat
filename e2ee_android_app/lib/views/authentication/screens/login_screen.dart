import 'package:e2ee_android_app/views/authentication/screens/pin_entry_screen.dart';
import 'package:e2ee_android_app/views/authentication/screens/sign_up_screen.dart';
import 'package:e2ee_android_app/views/homecreen/main_screen.dart';
import 'package:e2ee_models_app/configs/styles.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = "/LoginScreen";

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with MySafeState {
  static const double radius = 12;

  bool isLoading = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool isUsernameEntered = false;
  bool isPasswordEntered = false;
  bool passwordVisible = false;
  bool isBiometricAvailable = true;
  int failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_onUsernameChanged);
    passwordController.addListener(_onPasswordChanged);
    // _checkBiometricAvailability();
    _loadFailedAttempts();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
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

  /* Future<void> _checkBiometricAvailability() async {
    // Check if biometric authentication is available
    // This would typically use local_auth package
    try {
      // final LocalAuthentication auth = LocalAuthentication();
      // final bool isAvailable = await auth.canCheckBiometrics;
      // final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

      // For demo purposes, assuming biometric is available
      setState(() {
        isBiometricAvailable = true;
      });
    } catch (e) {
      setState(() {
        isBiometricAvailable = false;
      });
    }
  }*/

  Future<void> _loadFailedAttempts() async {
    // Load failed attempts from secure storage
    // This would typically use flutter_secure_storage
    try {
      // final storage = FlutterSecureStorage();
      // final attempts = await storage.read(key: 'failed_attempts');
      // failedAttempts = int.tryParse(attempts ?? '0') ?? 0;

      // For demo purposes
      failedAttempts = 0;
    } catch (e) {
      failedAttempts = 0;
    }
  }

  Future<void> _saveFailedAttempts() async {
    // Save failed attempts to secure storage
    try {
      // final storage = FlutterSecureStorage();
      // await storage.write(key: 'failed_attempts', value: failedAttempts.toString());
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _triggerDataWipe() async {
    // Implement data wipe functionality
    try {
      // Clear all user data, keys, messages, etc.
      // final storage = FlutterSecureStorage();
      // await storage.deleteAll();

      MyToast.showError(
        context: context,
        msg: "Security breach detected. All data has been wiped.",
      );

      // Navigate to setup screen or exit app
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/SetupScreen",
        (route) => false,
      );
    } catch (e) {
      // Handle error
    }
  }

  bool get isFormValid {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final usernameValid = RegExp(r'^[a-z0-9]+$').hasMatch(username);
    return username.isNotEmpty && password.length >= 6 && usernameValid;
  }

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (!RegExp(r'^[a-z0-9]+$').hasMatch(username)) {
      MyToast.showError(
        context: context,
        msg: "Username must be lowercase and alphanumeric.",
      );
      return;
    }

    if (password.length < 6) {
      MyToast.showError(
        context: context,
        msg: "Password must be at least 6 characters.",
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      bool loginSuccess = true; // Change this based on your actual logic

      if (loginSuccess) {
        MyToast.showSuccess(context: context, msg: "Login successful");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PinEntryScreen(mode: PinScreenMode.set),
          ),
        );
      } else {
        failedAttempts++;
        await _saveFailedAttempts();

        if (failedAttempts >= 5) {
          await _triggerDataWipe();
        } else {
          MyToast.showError(
            context: context,
            msg:
                "Invalid credentials. ${5 - failedAttempts} attempts remaining.",
          );
        }
      }
    } catch (e) {
      MyToast.showError(
        context: context,
        msg: "Login failed. Please try again.",
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool didAuthenticate = true;

      if (didAuthenticate) {
        failedAttempts = 0;
        await _saveFailedAttempts();
        MyToast.showSuccess(
          context: context,
          msg: "Biometric authentication successful!",
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PinEntryScreen()),
        );
      }
    } catch (e) {
      MyToast.showError(
        context: context,
        msg: "Biometric authentication failed.",
      );
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, "/ForgotPasswordScreen");
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
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
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.grey,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
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
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey[400],
                    ),
                    onPressed: () {
                      setState(() => passwordVisible = !passwordVisible);
                    },
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _navigateToForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFormValid
                            ? primaryColor
                            : theme.disabledColor.withAlpha(75),
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                  onPressed: isFormValid && !isLoading ? _login : null,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.login),
                  label: Text(isLoading ? "Logging in..." : "Login"),
                ),
              ),
              if (isBiometricAvailable) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.password),
                    label: const Text("Use Digital Pin To Login"),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: _navigateToSignup,
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                    child: const Text("Sign up"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
