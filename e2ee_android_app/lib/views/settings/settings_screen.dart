import 'dart:io';

import 'package:e2ee_android_app/backend/authentication/authentication_provider.dart';
import 'package:e2ee_android_app/backend/navigation/navigation_controller.dart';
import 'package:e2ee_android_app/utils/enums.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/configs/styles.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_toast.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../backend/authentication/authentication_controller.dart';
import '../../backend/navigation/navigation_arguments.dart';
import '../../backend/user/my_user_controller.dart';
import '../../backend/user/user_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with MySafeState {
  var username = '';
  var nickname = '';
  bool _biometricEnabled = false;
  late AuthenticationController authenticationController;
  late AuthenticationProvider authenticationProvider;
  late MyUserController userController;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      // Immediately try to upload the new image
      await _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_profileImage == null) return;

    final success = await userController.updateProfile(name: nickname, profilePhoto: _profileImage);

    if (success) {
      MyToast.showSuccess(context: context, msg: 'Profile picture updated');
      // The profile picture URL will be saved to SharedPreferences by the controller.
      // We can then reload it here if we want to display the updated image immediately.
      _loadProfilePicture();
    } else {
      MyToast.showError(context: context, msg: 'Failed to update profile picture');
    }
  }

  Future<void> _loadProfilePicture() async {
    final profilePicPath = await SharedPrefManager().getString('profile_pic_path');
    if (profilePicPath != null && profilePicPath.isNotEmpty) {
      setState(() {
        _profileImage = File(profilePicPath);
      });
    }
  }

  Future<void> _showEditNameDialog() async {
    final TextEditingController controller = TextEditingController(text: nickname);
    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Nickname'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter your nickname'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final success = await userController.updateDisplayName(result);
      if (success) {
        setState(() {
          nickname = result;
        });
        MyToast.showSuccess(context: context, msg: 'Profile updated');
      } else {
        MyToast.showError(context: context, msg: 'Failed to update');
      }
    }
  }

  Future<void> _getNames() async {
    var _u = await SharedPrefManager().getString(MySharedPreferenceVariables.username) ?? "";
    var _n = await SharedPrefManager().getString(MySharedPreferenceVariables.nickname) ?? "";

    username = _u;
    nickname = _n;

    setState(() {});
  }

  Future<void> _logoutAndWipeData() async {
    await authenticationController.logout();
    await authenticationController.wipeAllAuthData();

    if (!mounted) return;

    NavigationController.navigateToLoginScreen(
      navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamedAndRemoveUntil),
    );
  }

  @override
  void initState() {
    super.initState();
    authenticationProvider = context.read<AuthenticationProvider>();
    authenticationController = AuthenticationController(authenticationProvider: authenticationProvider);
    userController = MyUserController(repository: UserRepository(), authenticationProvider: authenticationProvider);
    _getNames();
    _loadProfilePicture();
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
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                alignment: Alignment.topLeft,
                padding: EdgeInsets.only(top: 40, left: 24),
                child: Text(
                  "Profile",
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      // User Initial with Edit Button
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: isDark ? Colors.grey[800] : Styles.grey400,
                            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                            child: _profileImage == null
                                ? Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : "?",
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentColor,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      // Username
                      Text(
                        nickname.isNotEmpty ? nickname : "No Nickname",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                      ),
                      Text(
                        "@" + username,
                        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
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
                SizedBox(height: 10),
                _settingTile(
                  icon: Icons.person_outline,
                  title: "Edit Nickname",
                  onTap: _showEditNameDialog, // Username editing
                ),
                _settingTile(
                  icon: Icons.pin_outlined,
                  title: "Change PIN",
                  onTap: () async {
                    await NavigationController.navigateToPinEntryScreen(
                      navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamed),
                      arguments: PinEntryScreenNavigationArguments(mode: PinScreenMode.changeOld),
                    );
                  },
                ),
                _settingTile(
                  icon: Icons.security_update_warning,
                  title: "Change Duress PIN",
                  onTap: () async {
                    await NavigationController.navigateToDuressPinEntryScreen(
                      navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamed),
                      arguments: PinEntryScreenNavigationArguments(mode: PinScreenMode.verifyCurrentPin),
                    );
                  },
                ),
                _biometricTile(),
                _settingTile(icon: CupertinoIcons.doc_text, title: "Terms of Service", onTap: () {}),
                _settingTile(icon: CupertinoIcons.lock_shield, title: "Privacy Policy", onTap: () {}),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    "Log out",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out? All your local data will be wiped.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Dismiss dialog
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                _logoutAndWipeData();
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        );
                      },
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

  Widget _settingTile({required IconData icon, required String title, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Styles.grey400),
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
              const SizedBox(width: 7),
              // Fingerprint Icon
              Icon(Icons.fingerprint, color: Styles.grey700, size: 22),
              const SizedBox(width: 18),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Biometric Login",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Text(_biometricEnabled ? "Enabled" : "Disabled", style: TextStyle(fontSize: 11.5, color: _biometricEnabled ? Colors.green[700] : Colors.grey[600])),
                  ],
                ),
              ),
              // Switch
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _biometricEnabled,
                  onChanged: (bool value) async {
                    if (value) {
                      final canBiometric = await authenticationController.canCheckBiometrics();
                      if (!canBiometric) {
                        MyToast.showError(context: context, msg: "Biometric not supported on this device.");
                        return;
                      }
                      final enabled = await authenticationController.enableBiometric(true);
                      if (enabled) {
                        final success = await authenticationController.authenticateWithBiometric();
                        if (success) {
                          setState(() {
                            _biometricEnabled = true;
                          });
                          MyToast.showSuccess(context: context, msg: "Biometric login enabled!");
                        } else {
                          await authenticationController.enableBiometric(false);
                          MyToast.showError(context: context, msg: "Biometric setup failed or cancelled.");
                        }
                      }
                    } else {
                      await authenticationController.enableBiometric(false);
                      setState(() {
                        _biometricEnabled = false;
                      });
                      MyToast.showSuccess(context: context, msg: "Biometric login disabled.");
                    }
                  },
                  activeColor: Styles.grey400,
                  inactiveThumbColor: Colors.grey[300],
                  inactiveTrackColor: Colors.grey[300]?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.only(left: 54, right: 8), child: Divider(height: 0, thickness: 0.3)),
      ],
    );
  }
}
