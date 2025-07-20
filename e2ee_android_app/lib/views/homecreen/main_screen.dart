import 'dart:convert';

import 'package:e2ee_android_app/configs/constants.dart';
import 'package:e2ee_android_app/configs/font_manager.dart';
import 'package:e2ee_android_app/views/calls/screens/calls_screen.dart';
import 'package:e2ee_android_app/views/chats/screens/chat_list_screen.dart';
import 'package:e2ee_android_app/views/files_and_media/files_media_screen.dart';
import 'package:e2ee_android_app/views/settings/settings_screen.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../backend/chats/chat_repository.dart';
import '../../backend/chats/chats_controller.dart';
import '../../backend/chats/chats_provider.dart';
import '../../backend/common/app_state.dart';
import '../../backend/common/dependency_injection.dart';
import '../../backend/notification/notification_service.dart';
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

  late final ChatRepository _chatRepository;
  late final ChatProvider _chatProvider;
  late final ChatController _chatController;
  late final AppState _appState;

  String _currentUserId = '';
  String _currentUserToken = '';

  final List<Widget> _screens = [
    ChatListScreen(),
    CallsScreen(),
    // FilesMediaScreen(),
    SettingsScreen(username: "rishi234")
  ];

  Future<void> _initializeSocket() async {
    _currentUserId =
        await SharedPrefManager().getString('current_user_id') ?? '';
    _currentUserToken = await SharedPrefManager()
        .getString(MySharedPreferenceVariables.authToken) ??
        '';

    _chatRepository.initPusher(
      userId: _currentUserId,
      token: _currentUserToken,
      onMessageReceived: _handleIncomingMessage,
    );
  }

  void _handleIncomingMessage(dynamic data) async {
    try {
      final messageData =
      data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

      final senderId = messageData['sender_id']?.toString() ?? '';
      final receiverId = messageData['receiver_id']?.toString() ?? '';
      final message = messageData['message']?.toString() ?? '';
      final timeStr = messageData['timestamp']?.toString() ?? '';

      final bool isMe = senderId == _currentUserId;
      final otherUserId = isMe ? receiverId : senderId;

      final DateTime time = DateTime.tryParse(timeStr) ?? DateTime.now();

      final chatMessage = ChatMessageModel(
        id: messageData['id']?.toString() ?? '',
        senderId: senderId,
        message: message,
        timestamp: time,
        isMe: isMe,
        status: 'delivered',
      );

      _chatProvider.addMessageFor(otherUserId, chatMessage);
      await _chatController.saveMessageToHive(
          chatId: otherUserId, message: chatMessage);

      List<ChatUserModel> users =
      List<ChatUserModel>.from(_chatProvider.chatUsers.getList());

      int index = users.indexWhere((u) => u.id == otherUserId);
      ChatUserModel user;
      String name;
      if (index == -1) {
        ChatUserModel? fetched = await _chatRepository.fetchChatUser(
          userId: otherUserId,
          token: _currentUserToken,
        );
        name = fetched?.name.isNotEmpty == true
            ? fetched!.name
            : (messageData['sender_name'] ?? messageData['receiver_name'] ?? otherUserId);
        String avatar = name.toString().isNotEmpty ? name[0].toUpperCase() : '';
        user = ChatUserModel(
          id: otherUserId,
          name: name,
          avatar: avatar,
          lastMessage: message,
          lastMessageTime: timeStr,
          unreadCount: isMe ? 0 : 1,
        );
      } else {
        user = users[index];
        if (user.name.isEmpty || user.name == user.id) {
          ChatUserModel? fetched = await _chatRepository.fetchChatUser(
            userId: otherUserId,
            token: _currentUserToken,
          );
          if (fetched != null && fetched.name.isNotEmpty) {
            user.name = fetched.name;
            user.avatar = fetched.name[0].toUpperCase();
          }
        }
        name = user.name;
        user.lastMessage = message;
        user.lastMessageTime = timeStr;
        if (!isMe) user.unreadCount = user.unreadCount + 1;
        users..removeAt(index);
      }

      await _chatController.addUserToChatList(user);

      final displayName = name.isNotEmpty ? name : otherUserId;

      if (_appState.lifecycleState == AppLifecycleState.resumed) {
        if (_appState.currentChattingWithUserId != otherUserId) {
          // Use sender name as title, message as body
          _appState.showCustomNotification(displayName, "");
        }
      } else if (_appState.lifecycleState == AppLifecycleState.paused) {
        NotificationService().showSystemNotification(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          displayName,  // title
          "",      // body
        );
      }
    } catch (e) {
      // ignore errors parsing the message
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatProvider = context.read<ChatProvider>();
    _appState = context.read<AppState>();
    _chatRepository = ChatRepository();
    _chatController = ChatController(
      chatProvider: _chatProvider,
    );
    _initializeSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatRepository.disposePusher();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState.setLifecycleState(state);
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
            /*FlashyTabBarItem(
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
            ),*/
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
