import 'package:e2ee_android_app/views/homecreen/main_screen.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

enum PinScreenMode { set, confirm, verify }

class PinEntryScreen extends StatefulWidget {
  final PinScreenMode mode;
  final String? initialPin; // Used for confirm step

  const PinEntryScreen({Key? key, this.mode = PinScreenMode.verify, this.initialPin}) : super(key: key);

  @override
  _PinEntryScreenState createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> with MySafeState {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int failedAttempts = 0;
  bool isLoading = false;
  String? errorMessage;
  String? newPin;

  @override
  void initState() {
    super.initState();
    // Auto-focus the PIN input when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

    // Simulate authentication delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (pin == "12345678") {
      // PIN is correct - navigate to next screen
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MainScreen(),));
      }
    } else {
      // PIN is incorrect
      setState(() {
        failedAttempts++;
        isLoading = false;

        if (failedAttempts >= 5) {
          errorMessage = "Too many failed attempts. All data will be wiped.";
          _wipeAppData();
        } else {
          errorMessage = "Incorrect PIN. ${5 - failedAttempts} attempts remaining.";
        }
      });

      // Clear the PIN input
      _pinController.clear();
    }
  }

  void _wipeAppData() {
    // Simulate data wipe process
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Security Alert'),
            content: const Text(
              'All app data has been wiped for security purposes.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Exit app or redirect to initial setup
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    final defaultPinTheme = PinTheme(
      width: 45,
      height: 45,
      textStyle: TextStyle(
        fontSize: 16,
        color: themeData.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
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

    late final String title;
    late final String subtitle;
    switch (widget.mode) {
      case PinScreenMode.set:
        title = "Set Your PIN";
        subtitle = "Choose a 6 or 8-digit PIN for secure access";
        break;
      case PinScreenMode.confirm:
        title = "Confirm Your PIN";
        subtitle = "Re-enter the PIN to confirm";
        break;
      case PinScreenMode.verify:
        title = "Enter Your PIN";
        subtitle = "Enter your PIN to access secure chat";
        break;
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
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

                  // Security Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: themeData.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.security,
                      size: 40,
                      color: themeData.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: themeData.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),
                  Pinput(
                    controller: _pinController,
                    focusNode: _focusNode,
                    length: 8,
                    obscureText: true,
                    obscuringCharacter: '●',
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    errorPinTheme: errorPinTheme,
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
                          const Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Loading Indicator
                  if (isLoading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        themeData.primaryColor,
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeData.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Security: 5 failed attempts will trigger data wipe',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // Handle forgot PIN
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Forgot PIN?'),
                              content: const Text(
                                'Please contact support or reset your account to recover access.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    // Navigate to account recovery
                                  },
                                  child: const Text('Reset Account'),
                                ),
                              ],
                            ),
                      );
                    },
                    child: Text(
                      'Forgot PIN?',
                      style: TextStyle(
                        color: themeData.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
