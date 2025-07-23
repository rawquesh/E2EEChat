import 'package:e2ee_android_app/backend/authentication/authentication_controller.dart';
import 'package:e2ee_android_app/backend/authentication/authentication_provider.dart';
import 'package:e2ee_android_app/backend/navigation/navigation_controller.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_toast.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backend/common/app_theme/app_theme_controller.dart';
import '../../backend/common/app_theme/app_theme_provider.dart';
import '../../backend/navigation/navigation_arguments.dart';
import '../authentication/screens/pin_entry_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String username;

  const SettingsScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with MySafeState {
  late AuthenticationController authenticationController;
  late AuthenticationProvider authenticationProvider;
  bool biometricEnabled = false;

  var username = '';

  Future<void> getUsername() async {
    var _u =
        await SharedPrefManager().getString(
          MySharedPreferenceVariables.username,
        ) ??
        "null";

    username = _u;
    setState(() {});
  }

  Future<void> _loadBiometricState() async {
    bool isEnabled = await authenticationController.isBiometricEnabled();
    setState(() {
      biometricEnabled = isEnabled;
    });
  }

  @override
  void initState() {
    super.initState();
    getUsername();
    authenticationProvider = context.read<AuthenticationProvider>();
    authenticationController = AuthenticationController(
      authenticationProvider: authenticationProvider,
    );
    _loadBiometricState();
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    final accentColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Curved Header
          Stack(
            children: [
              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                alignment: Alignment.topLeft,
                padding: EdgeInsets.only(top: 40, left: 24),
                child: Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      // User Initial
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.amber[700],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : "?",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Username
                      Text(
                        username,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Edit Profile Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 34,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          // Navigate to edit profile
                        },
                        child: Text(
                          "Edit Profile",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildThemeSwitchItem(),
                SizedBox(height: 10),
                _settingTile(
                  icon: Icons.person_outline,
                  title: "Edit Profile",
                  onTap: () {}, // Username editing
                ),
                // _settingTile(
                //   icon: Icons.lock_outline,
                //   title: "Change Password",
                //   onTap: () {},
                // ),
                _settingTile(
                  icon: Icons.pin_outlined,
                  title: "Change PIN",
                  onTap: () async {
                    await NavigationController.navigateToPinEntryScreen(
                      navigationOperationParameters:
                          NavigationOperationParameters(
                            context: context,
                            navigationType: NavigationType.pushNamed,
                          ),
                      arguments: PinEntryScreenNavigationArguments(
                        mode: PinScreenMode.changeOld,
                      ),
                    );
                  },
                ),
                _biometricTile(),
                // _settingTile(
                //   icon: Icons.timer_outlined,
                //   title: "Self-Destruct Messages",
                //   onTap: () {},
                // ),
                // _settingTile(
                //   icon: Icons.phonelink_lock_outlined,
                //   title: "App Lock",
                //   onTap: () {},
                // ),
                // _settingTile(
                //   icon: Icons.notifications_active_outlined,
                //   title: "Chat Notifications",
                //   onTap: () {},
                // ),
                // _settingTile(
                //   icon: CupertinoIcons.phone,
                //   title: "Call Notifications",
                //   onTap: () {},
                // ),
                // _settingTile(
                //   icon: CupertinoIcons.question_circle,
                //   title: "Help Center & FAQ",
                //   onTap: () {},
                // ),
                // _settingTile(
                //   icon: CupertinoIcons.lightbulb,
                //   title: "Feature Requests",
                //   onTap: () {},
                // ),
                _settingTile(
                  icon: CupertinoIcons.doc_text,
                  title: "Terms of Service",
                  onTap: () {},
                ),
                _settingTile(
                  icon: CupertinoIcons.lock_shield,
                  title: "Privacy Policy",
                  onTap: () {},
                ),
                _settingTile(
                  icon: CupertinoIcons.info_circle,
                  title: "App Info & Version",
                  onTap: () {},
                ),
                // Logout - visually separated
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    "Log out",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    NavigationController.navigateToLoginScreen(
                      navigationOperationParameters:
                          NavigationOperationParameters(
                            context: context,
                            navigationType:
                                NavigationType.pushNamedAndRemoveUntil,
                          ),
                    );
                  },
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.amber[700]),
          title: Text(title, style: TextStyle(fontSize: 12)),
          trailing: Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        Divider(height: 0, thickness: 0.3, indent: 18, endIndent: 8),
      ],
    );
  }

  Widget _biometricTile() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              // Fingerprint Icon
              Container(
                width: 38,
                height: 38,
                child: Icon(Icons.fingerprint, color: Colors.amber[700], size: 22),
              ),
              const SizedBox(width: 10),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Biometric Login",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      biometricEnabled ? "Enabled" : "Disabled",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: biometricEnabled
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Switch
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: biometricEnabled,
                  onChanged: (bool value) async {
                    if (value) {
                      final canBiometric = await authenticationController.canCheckBiometrics();
                      if (!canBiometric) {
                        MyToast.showError(
                          context: context,
                          msg: "Biometric not supported on this device.",
                        );
                        return;
                      }
                      final enabled = await authenticationController.enableBiometric(true);
                      if (enabled) {
                        final success = await authenticationController.authenticateWithBiometric();
                        if (success) {
                          setState(() {
                            biometricEnabled = true;
                          });
                          MyToast.showSuccess(
                            context: context,
                            msg: "Biometric login enabled!",
                          );
                        } else {
                          await authenticationController.enableBiometric(false);
                          MyToast.showError(
                            context: context,
                            msg: "Biometric setup failed or cancelled.",
                          );
                        }
                      }
                    } else {
                      await authenticationController.enableBiometric(false);
                      setState(() {
                        biometricEnabled = false;
                      });
                      MyToast.showSuccess(
                        context: context,
                        msg: "Biometric login disabled.",
                      );
                    }
                  },
                  activeColor: Colors.amber[700],
                  inactiveThumbColor: Colors.grey[300],
                  inactiveTrackColor: Colors.grey[300]?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 54, right: 8),
          child: Divider(height: 0, thickness: 0.3),
        ),
      ],
    );
  }

  Widget _buildThemeSwitchItem() {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.darkThemeMode;

        return Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            color: Colors.transparent, // Or theme background color
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sun
                  GestureDetector(
                    onTap: () async {
                      if (isDark) {
                        AppThemeController controller = AppThemeController(
                          appThemeProvider: themeProvider,
                        );
                        await controller.setDarkThemeEnabledInSharedPreferences(
                          false,
                        );
                        controller.updateThemeMode(false);
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.ease,
                      decoration: BoxDecoration(
                        color: !isDark ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        size: 24,
                        color:
                            !isDark
                                ? Colors.black
                                : themeData.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(width: 18),
                  // Moon
                  GestureDetector(
                    onTap: () async {
                      if (!isDark) {
                        AppThemeController controller = AppThemeController(
                          appThemeProvider: themeProvider,
                        );
                        await controller.setDarkThemeEnabledInSharedPreferences(
                          true,
                        );
                        controller.updateThemeMode(true);
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.ease,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.13),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.nightlight_round,
                        size: 24,
                        color: isDark ? Colors.black : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
