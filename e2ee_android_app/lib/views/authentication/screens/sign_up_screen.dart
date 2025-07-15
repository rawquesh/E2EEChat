import 'package:e2ee_android_app/views/authentication/screens/pin_entry_screen.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../backend/navigation/navigation_arguments.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  static const String routeName = "/SignUpScreen";

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with MySafeState {
  static const double radius = 12;

  bool isLoading = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  bool isUsernameEntered = false;
  bool isPasswordEntered = false;
  bool isConfirmPasswordEntered = false;
  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    usernameController.addListener(_onUsernameChanged);
    passwordController.addListener(_onPasswordChanged);
    confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
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

  void _onConfirmPasswordChanged() {
    setState(() {
      isConfirmPasswordEntered =
          confirmPasswordController.text.trim().isNotEmpty;
    });
  }

  bool _isUsernameValid() {
    final username = usernameController.text.trim();
    return username.isNotEmpty && RegExp(r'^[a-z0-9]+$').hasMatch(username);
  }

  bool _isPasswordValid() {
    final password = passwordController.text.trim();
    return password.length >= 8;
  }

  bool _isPasswordStrong() {
    final password = passwordController.text.trim();
    // Check for at least one uppercase, one lowercase, one number, and one special character
    return password.length >= 8 &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  bool _doPasswordsMatch() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  bool get isFormValid {
    return _isUsernameValid() &&
        _isPasswordValid() &&
        _doPasswordsMatch() &&
        isUsernameEntered &&
        isPasswordEntered &&
        isConfirmPasswordEntered;
  }

  String? _getUsernameError() {
    final username = usernameController.text.trim();
    if (username.isEmpty) return null;
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(username)) {
      return "Username must be lowercase and alphanumeric only";
    }
    return null;
  }

  String? _getPasswordError() {
    final password = passwordController.text.trim();
    if (password.isEmpty) return null;
    if (password.length < 8) {
      return "Password must be at least 8 characters";
    }
    return null;
  }

  String? _getConfirmPasswordError() {
    final confirmPassword = confirmPasswordController.text.trim();
    if (confirmPassword.isEmpty) return null;
    if (!_doPasswordsMatch()) {
      return "Passwords do not match";
    }
    return null;
  }

  Color _getPasswordStrengthColor() {
    final password = passwordController.text.trim();
    if (password.isEmpty) return Colors.grey;
    if (password.length < 8) return Colors.red;
    if (_isPasswordStrong()) return Colors.green;
    return Colors.orange;
  }

  String _getPasswordStrengthText() {
    final password = passwordController.text.trim();
    if (password.isEmpty) return "Password strength";
    if (password.length < 8) return "Weak - too short";
    if (_isPasswordStrong()) return "Strong";
    return "Medium - add uppercase, numbers, symbols";
  }

  Future<void> _signUp() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // Final validation
    if (!_isUsernameValid()) {
      MyToast.showError(
        context: context,
        msg: "Username must be lowercase and alphanumeric only.",
      );
      return;
    }

    if (!_isPasswordValid()) {
      MyToast.showError(
        context: context,
        msg: "Password must be at least 8 characters.",
      );
      return;
    }

    if (!_doPasswordsMatch()) {
      MyToast.showError(context: context, msg: "Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // For demo - simulate successful registration
      bool registrationSuccess = true; // Replace with actual registration logic

      if (registrationSuccess) {
        MyToast.showSuccess(
          context: context,
          msg: "Account created successfully!",
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PinEntryScreen(mode: PinScreenMode.set),
          ),
        );
      } else {
        MyToast.showError(
          context: context,
          msg: "Registration failed. Please try again.",
        );
      }
    } catch (e) {
      MyToast.showError(
        context: context,
        msg: "An error occurred. Please try again.",
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
              Icon(Icons.person_add_outlined, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              Text(
                "Create Secure Account",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Join the most secure chat platform",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Username Field
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
                  suffixIcon:
                      isUsernameEntered
                          ? Icon(
                            _isUsernameValid()
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                _isUsernameValid() ? Colors.green : Colors.red,
                          )
                          : null,
                  errorText: _getUsernameError(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(
                      color:
                          isUsernameEntered
                              ? (_isUsernameValid() ? Colors.green : Colors.red)
                              : Colors.grey[300]!,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Must be lowercase and alphanumeric only",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                obscureText: !passwordVisible,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withAlpha(50),
                  labelText: "Password",
                  hintText: "Create a strong password",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPasswordEntered)
                        Icon(
                          _isPasswordValid() ? Icons.check_circle : Icons.error,
                          color: _getPasswordStrengthColor(),
                        ),
                      IconButton(
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() => passwordVisible = !passwordVisible);
                        },
                      ),
                    ],
                  ),
                  errorText: _getPasswordError(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(
                      color:
                          isPasswordEntered
                              ? _getPasswordStrengthColor()
                              : Colors.grey[300]!,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Password Strength Indicator
              if (isPasswordEntered)
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getPasswordStrengthColor(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPasswordStrengthText(),
                      style: TextStyle(
                        color: _getPasswordStrengthColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Confirm Password Field
              TextField(
                controller: confirmPasswordController,
                focusNode: confirmPasswordFocusNode,
                obscureText: !confirmPasswordVisible,
                textInputAction: TextInputAction.done,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withAlpha(50),
                  labelText: "Confirm Password",
                  hintText: "Re-enter your password",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.grey,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConfirmPasswordEntered)
                        Icon(
                          _doPasswordsMatch()
                              ? Icons.check_circle
                              : Icons.error,
                          color:
                              _doPasswordsMatch() ? Colors.green : Colors.red,
                        ),
                      IconButton(
                        icon: Icon(
                          confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(
                            () =>
                                confirmPasswordVisible =
                                    !confirmPasswordVisible,
                          );
                        },
                      ),
                    ],
                  ),
                  errorText: _getConfirmPasswordError(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(
                      color:
                          isConfirmPasswordEntered
                              ? (_doPasswordsMatch()
                                  ? Colors.green
                                  : Colors.red)
                              : Colors.grey[300]!,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radius),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Continue Button
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
                  onPressed: isFormValid && !isLoading ? _signUp : null,
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
                          : const Icon(Icons.person_add),
                  label: Text(isLoading ? "Creating Account..." : "Continue"),
                ),
              ),

              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: _navigateToLogin,
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                    child: const Text("Login"),
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
