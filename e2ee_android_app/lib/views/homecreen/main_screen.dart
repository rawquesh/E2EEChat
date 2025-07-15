import 'package:e2ee_android_app/configs/constants.dart';
import 'package:e2ee_android_app/configs/font_manager.dart';
import 'package:e2ee_android_app/views/calls/screens/calls_screen.dart';
import 'package:e2ee_android_app/views/chats/screens/chat_list_screen.dart';
import 'package:e2ee_android_app/views/files_and_media/files_media_screen.dart';
import 'package:e2ee_android_app/views/settings/settings_screen.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../backend/common/dependency_injection.dart';
import '../common/components/flashy_tab_bar.dart';
import '../tab_state.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = "/MainScreen";

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin, MySafeState, WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ChatListScreen(),
    CallsScreen(),
    FilesMediaScreen(),
    SettingsScreen(username: "rishi234")
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserModel userModel =
        DependencyInjection.authenticationProvider.userModel.get() ??
        UserModel();
    super.pageBuild();
    return ChangeNotifierProvider(
      create: (_) => TabState(),
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: FlashyTabBar(
          animationDuration: const Duration(milliseconds: 300),
          selectedIndex: _currentIndex,
          onItemSelected: (index) {
            _currentIndex = index;
            mySetState();
          },
          showElevation: true,
          items: [
            FlashyTabBarItem(
              icon: Image.asset(
                AppAssets.chat_icon,
                height: 26,
                width: 26,
                color: themeData.primaryColor,
              ),
              title: Text(
                'Chats',
                style:
                    themeData.textTheme.labelSmall
                        ?.copyWith(
                          fontSize: 10,
                          color: themeData.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        )
                        .withEpilogue,
              ),
              activeColor: themeData.primaryColor,
              inactiveColor: themeData.primaryColor.withValues(alpha: 0.4),
            ),
            FlashyTabBarItem(
              icon: Image.asset(
                AppAssets.call_icon,
                height: 26,
                width: 26,
                color: themeData.primaryColor,
              ),
              title: Text(
                'Calls & Contacts',
                style:
                    themeData.textTheme.labelSmall
                        ?.copyWith(fontSize: 10,
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,)
                        .withEpilogue,
              ),
              activeColor: themeData.primaryColor,
              inactiveColor: themeData.primaryColor.withValues(alpha: 0.4),
            ),
            FlashyTabBarItem(
              icon: Image.asset(
                AppAssets.files_icon,
                height: 26,
                width: 26,
                color: themeData.primaryColor,
              ),
              title: Text(
                'Files & Media',
                style:
                    themeData.textTheme.labelSmall
                        ?.copyWith(fontSize: 10,
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,)
                        .withEpilogue,
              ),
              activeColor: themeData.primaryColor,
              inactiveColor: themeData.primaryColor.withValues(alpha: 0.4),
            ),
            FlashyTabBarItem(
              icon: Image.asset(
                AppAssets.settings_icon,
                height: 26,
                width: 26,
                color: themeData.primaryColor,
              ),
              title: Text(
                'Settings',
                style:
                    themeData.textTheme.labelSmall
                        ?.copyWith(fontSize: 10,
                      color: themeData.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,)
                        .withEpilogue,
              ),
              activeColor: themeData.primaryColor,
              inactiveColor: themeData.primaryColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
