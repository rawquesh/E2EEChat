import 'package:e2ee_android_app/backend/authentication/authentication_controller.dart';
import 'package:e2ee_android_app/backend/authentication/authentication_provider.dart';
import 'package:e2ee_android_app/backend/navigation/navigation_controller.dart';
import 'package:e2ee_android_app/utils/enums.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';

class VaultPinEntryScreen extends StatefulWidget {
  final VoidCallback onPinVerified;
  final PinScreenMode mode;

  const VaultPinEntryScreen({Key? key, required this.onPinVerified, required this.mode}) : super(key: key);

  @override
  _VaultPinEntryScreenState createState() => _VaultPinEntryScreenState();
}

class _VaultPinEntryScreenState extends State<VaultPinEntryScreen> with MySafeState {
  late AuthenticationController authenticationController;
  late AuthenticationProvider authenticationProvider;

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int failedAttempts = 0;
  bool isLoading = false;
  String? errorMessage;
  String? firstPin;
  late PinScreenMode currentMode;

  @override
  void initState() {
    MyPrint.printOnConsole("VaultPinEntryScreen initState called with mode: ${widget.mode}");
    super.initState();
    authenticationProvider = context.read<AuthenticationProvider>();
    authenticationController = AuthenticationController(authenticationProvider: authenticationProvider);

    currentMode = widget.mode;
    MyPrint.printOnConsole("VaultPinEntryScreen initialized with mode: $currentMode");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinCompleted(String pin) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    if (currentMode == PinScreenMode.set) {
      final storedDuressPin = await SecureStorageManager().getString(MySharedPreferenceVariables.duressPinKey);
      final storedLoginPin = await SecureStorageManager().getString(MySharedPreferenceVariables.pinKey);

      if (storedDuressPin != null && storedDuressPin == pin) {
        _wipeAppData();
        setState(() {
          errorMessage = "This PIN is already in use. Please choose a different one.";
          currentMode = PinScreenMode.set;
          firstPin = null;
          _pinController.clear();
          isLoading = false;
        });
        return;
      }
      if (storedLoginPin != null && storedLoginPin == pin) {
        setState(() {
          errorMessage = "This PIN is already in use. Please choose a different one.";
          currentMode = PinScreenMode.set;
          firstPin = null;
          _pinController.clear();
          isLoading = false;
        });
        return;
      }

      firstPin = pin;

      setState(() {
        currentMode = PinScreenMode.confirm;
        _pinController.clear();
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
      return;
    } else if (currentMode == PinScreenMode.confirm) {
      if (firstPin == null) {
        setState(() {
          errorMessage = "Something went wrong. Please start over.";
          currentMode = PinScreenMode.set;
          firstPin = null;
          _pinController.clear();
          isLoading = false;
        });
        return;
      }
      if (firstPin == pin) {
        final result = await authenticationController.setNewPin(firstPin!, pin, isVaultPin: true);
        setState(() {
          isLoading = false;
        });
        if (result) {
          widget.onPinVerified();
        } else {
          setState(() {
            errorMessage = "Failed to save PIN. Please try again.";
            currentMode = PinScreenMode.set;
            firstPin = null;
            _pinController.clear();
          });
        }
      } else {
        setState(() {
          errorMessage = "PINs do not match. Please try again.";
          currentMode = PinScreenMode.set;
          firstPin = null;
          _pinController.clear();
          isLoading = false;
        });
      }
      return;
    } else if (currentMode == PinScreenMode.verify) {
      final isCorrect = await authenticationController.verifyPin(pin, isVaultPin: true);
      if (isCorrect) {
        if (mounted) {
          widget.onPinVerified();
        }
      } else {
        final storedDuressPin = await SecureStorageManager().getString(MySharedPreferenceVariables.duressPinKey);

        if (storedDuressPin != null && storedDuressPin == pin) {
          _wipeAppData();
          setState(() => errorMessage = "Duress PIN entered. All data will be wiped.");
          return;
        }

        setState(() {
          failedAttempts++;
          isLoading = false;
          if (failedAttempts >= 5) {
            errorMessage = "Too many failed attempts. All data will be wiped.";
            _wipeAppData();
          } else {
            errorMessage = "Incorrect PIN. ${5 - failedAttempts} attempts remaining.";
          }
          _pinController.clear();
        });
      }
      return;
    }
  }

  void _wipeAppData() async {
    // Wipe all authentication data
    authenticationController.wipeAllAuthData();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Alert'),
        content: const Text('All app data has been wiped for security purposes. You will need to register again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to login/registration
              NavigationController.navigateToLoginScreen(
                navigationOperationParameters: NavigationOperationParameters(
                  context: context,
                  navigationType: NavigationType.pushNamedAndRemoveUntil,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (currentMode) {
      case PinScreenMode.set:
        return "Set Your Vault PIN";
      case PinScreenMode.confirm:
        return "Confirm Your Vault PIN";
      case PinScreenMode.verify:
        return "Enter Your Vault PIN";
      default:
        return "Vault PIN";
    }
  }

  String _getSubtitle() {
    switch (currentMode) {
      case PinScreenMode.set:
        return "Choose a 4-digit PIN for your vault";
      case PinScreenMode.confirm:
        return "Re-enter the PIN to confirm";
      case PinScreenMode.verify:
        return "Enter your PIN to access your vault";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    MyPrint.printOnConsole("Building VaultPinEntryScreen with mode: $currentMode");

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 45,
      textStyle: TextStyle(fontSize: 16, color: themeData.colorScheme.onSurface, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        color: themeData.primaryColor.withValues(alpha: 0.05),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: themeData.primaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: themeData.primaryColor.withValues(alpha: 0.1),
        border: Border.all(color: themeData.primaryColor, width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.red, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(scrolledUnderElevation: 0, backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).viewInsets.bottom -
                    MediaQuery.of(context).padding.top -
                    kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: themeData.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Icon(currentMode == PinScreenMode.verify ? Icons.lock : Icons.security, size: 40, color: themeData.primaryColor),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getTitle(),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeData.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Pinput(
                      controller: _pinController,
                      focusNode: _focusNode,
                      length: 4,
                      obscureText: true,
                      obscuringCharacter: '●',
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      errorPinTheme: errorMessage != null ? errorPinTheme : null,
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      onCompleted: _onPinCompleted,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade700),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (isLoading) CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeData.primaryColor)),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
