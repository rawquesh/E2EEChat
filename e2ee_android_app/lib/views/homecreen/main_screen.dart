import 'dart:convert';

import 'package:e2ee_android_app/backend/webrtc/call_controller.dart';
import 'package:e2ee_android_app/backend/webrtc/call_provider.dart';
import 'package:e2ee_android_app/configs/constants.dart';
import 'package:e2ee_android_app/configs/font_manager.dart';
import 'package:e2ee_android_app/views/calls/screens/calls_screen.dart';
import 'package:e2ee_android_app/views/chats/screens/chat_list_screen.dart';
import 'package:e2ee_android_app/views/settings/settings_screen.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
// import 'package:e2ee_models_app/models/user/data_model/user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backend/chats/chat_repository.dart';
import '../../backend/chats/chats_controller.dart';
import '../../backend/chats/chats_provider.dart';
import '../../backend/common/app_state.dart';
// import '../../backend/common/dependency_injection.dart';
import '../../backend/navigation/navigation_arguments.dart';
import '../../backend/navigation/navigation_controller.dart';
import '../../backend/notification/notification_service.dart';
import '../../backend/self_destruct/self_destruct_service.dart';
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
  late CallController callController;
  late CallProvider callProvider;
  final SelfDestructService _selfDestructService = SelfDestructService();
  bool _isCallDialogShowing = false;

  String _currentUserId = '';
  String _currentUserToken = '';

  final List<Widget> _screens = [
    ChatListScreen(),
    CallsScreen(),
    SettingsScreen(),
  ];

  Future<void> _initializeSocket() async {
    callController = CallController();
    callProvider = context.read<CallProvider>();
    _currentUserId =
        await SharedPrefManager().getString(MySharedPreferenceVariables.currentUserId) ?? '';
    MyPrint.printOnConsole('userId: $_currentUserId');
    _currentUserToken =
        await SharedPrefManager().getString(
          MySharedPreferenceVariables.authToken,
        ) ??
        '';
    MyPrint.printOnConsole("auth_token: ${_currentUserToken}");

    _chatRepository.initPusher(
      userId: _currentUserId,
      token: _currentUserToken,
      onMessageReceived: _handleIncomingMessage,
    );

    callProvider.initController(
      userId: _currentUserId,
      token: _currentUserToken,
    );
    callProvider.callController.onIncomingCall = _showIncomingCallDialog;
  }

  void _showIncomingCallDialog(String callerId) async {
    if (_isCallDialogShowing) return;
    _isCallDialogShowing = true;

    ChatUserModel? user = _chatProvider.chatUsers.getList().firstWhere(
      (u) => u.id == callerId,
      orElse: () => ChatUserModel(id: callerId),
    );
    if (user.nickname.isEmpty) {
      final fetched = await _chatRepository.fetchChatUser(
        userId: callerId,
        token: _currentUserToken,
      );
      if (fetched != null) user = fetched;
    }

    /* callProvider.callController.setRemoteUserDetails(
      name: user.name,
      avatar: user.avatar,
    );*/

    final callerName = user.nickname.isNotEmpty ? user.nickname : callerId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Incoming Call \ud83d\udcf2'),
          content: Text('Call from: $callerName'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                callProvider.callController.endCall();
                _dismissCallDialog();
              },
              child: const Text('Decline'),
            ),
            TextButton(
              onPressed: () async {
                await callProvider.callController.acceptCall();
                _dismissCallDialog();

                ChatUserModel? user = _chatProvider.chatUsers
                    .getList()
                    .firstWhere(
                      (u) => u.id == callerId,
                      orElse: () => ChatUserModel(id: callerId),
                    );
                if (user.nickname.isEmpty) {
                  final fetched = await _chatRepository.fetchChatUser(
                    userId: callerId,
                    token: _currentUserToken,
                  );
                  if (fetched != null) user = fetched;
                }

                if (!mounted) return;
                NavigationController.navigateToVoiceCallScreen(
                  navigationOperationParameters: NavigationOperationParameters(
                    context: context,
                    navigationType: NavigationType.pushNamed,
                  ),
                  arguments: VoiceCallScreenNavigationArguments(user: user),
                );
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    ).then((_) => _isCallDialogShowing = false);
  }

  void _dismissCallDialog() {
    if (_isCallDialogShowing) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _isCallDialogShowing = false;
  }

  void _handleIncomingMessage(dynamic data) async {
    try {
      final messageData = data is String
          ? jsonDecode(data)
          : Map<String, dynamic>.from(data);
      debugPrint("messageData ==> ${messageData}");

      final senderId = messageData['sender_id']?.toString() ?? '';
      if (senderId.isEmpty) return; // Ignore invalid messages

      // if (username.isEmpty) {
      //   MyPrint.printOnConsole(
      //     "Username not in payload, fetching from API for ID: $senderId",
      //   );
      //   final fetchedUser = await _chatRepository.fetchChatUser(
      //     userId: senderId,
      //     token: _currentUserToken,
      //   );
      //   username = fetchedUser?.nickname ?? 'Unknown User';
      // }

      final receiverId = messageData['receiver_id']?.toString() ?? '';
      //final message = messageData['message']?.toString() ?? '';
      final message = messageData['message']['message']?.toString() ?? '';
      final tempDestructTimer = messageData['message']['destructTimer'] ?? 0;
      DateTime destructTimer = DateTime.now().add(
        Duration(seconds: tempDestructTimer),
      );
      if (tempDestructTimer == 0) {
        destructTimer = DateTime.now().add(Duration(days: 365 * 100));
      }
      debugPrint("tempDestructTimer1 ==> ${tempDestructTimer}");
      debugPrint("tempDestructTimer2 ==> ${destructTimer}");

      final timeStr = messageData['timestamp']?.toString() ?? '';
      final bool isMe = senderId == _currentUserId;
      final otherUserId = isMe ? receiverId : senderId;

      final DateTime time = DateTime.tryParse(timeStr) ?? DateTime.now();
      final String messageId = messageData['id']?.toString() ?? '';

      final chatMessage = ChatMessageModel(
        id: messageId.isNotEmpty ? messageId : MyUtils.getNewId(),
        senderId: senderId,
        message: message,
        timestamp: DateTime.now(),
        isMe: isMe,
        status: 'delivered',
        destructTimestamp: destructTimer,
      );

      _chatProvider.addMessageFor(otherUserId, chatMessage);
      await _chatController.saveMessageToHive(
        chatId: otherUserId,
        message: chatMessage,
      );

      List<ChatUserModel> users = List<ChatUserModel>.from(
        _chatProvider.chatUsers.getList(),
      );

      int index = users.indexWhere((u) => u.id == otherUserId);
      ChatUserModel user;

      var username = messageData['message']['username']?.toString() ?? '';

      var nickname = messageData['message']['nickname']?.toString() ?? '';


      if (index == -1) {
        String avatar = username.isNotEmpty
            ? username[0].toUpperCase()
            : '?';
        user = ChatUserModel(
          id: otherUserId,
          nickname: nickname,
          username: username,
          avatar: avatar,
          lastMessage: message,
          lastMessageTime: time.toIso8601String(),
          unreadCount: isMe ? 0 : 1,
        );
      } else {
        user = users[index];
        user.nickname = nickname; // Ensure name is up-to-date
        user.username = username; 
        user.lastMessage = message;
        user.lastMessageTime = time.toIso8601String();
        if (!isMe && _appState.currentChattingWithUserId != otherUserId) {
          user.unreadCount = user.unreadCount + 1;
        }
      }

      await _chatController.addUserToChatList(user);

      if (_appState.lifecycleState == AppLifecycleState.resumed) {
        if (_appState.currentChattingWithUserId != otherUserId) {
          _appState.showCustomNotification(
            'New message from $nickname',
            //message
            message.startsWith(imageTypeChat)
                ? "Image"
                : message.startsWith(audioTypeChat)
                ? "Audio"
                : message.startsWith(videoTypeChat)
                ? "Video"
                : message.startsWith(docTypeChat)
                ? "Document"
                : message,
          );
        }
      } else if (_appState.lifecycleState == AppLifecycleState.paused) {
        NotificationService().showSystemNotification(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          'New message from $nickname',
          //message,
          message.startsWith(imageTypeChat)
              ? "Image"
              : message.startsWith(audioTypeChat)
              ? "Audio"
              : message.startsWith(videoTypeChat)
              ? "Video"
              : message.startsWith(docTypeChat)
              ? "Document"
              : message,
        );
      }
    } catch (e) {
      MyPrint.printOnConsole("Error in _handleIncomingMessage: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatProvider = context.read<ChatProvider>();
    _appState = context.read<AppState>();
    _chatRepository = ChatRepository();
    _chatController = ChatController(chatProvider: _chatProvider);
    _initializeSocket();
    _selfDestructService.start(
      onMessagesDeletedCallback: (chatId, deletedMessages) async {
        if (mounted) {
          final provider = context.read<ChatProvider>();
          provider.removeMessages(chatId, deletedMessages);

          final remaining = provider.getMessagesFor(chatId);
          final lastMsg = remaining.isNotEmpty ? remaining.last : null;

          await _chatController.updateUserLastMessage(
            userId: chatId,
            lastMessage: lastMsg?.message ?? '',
            lastMessageTime: lastMsg?.timestamp ?? DateTime.now(),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatRepository.disposePusher();
    _selfDestructService.stop();
    callProvider.callController.onIncomingCall = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState.setLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        MyPrint.printOnConsole("App Resumed");
        _selfDestructService.start(
          onMessagesDeletedCallback: (chatId, deletedMessages) async {
            if (mounted) {
              final provider = context.read<ChatProvider>();
              provider.removeMessages(chatId, deletedMessages);

              final remaining = provider.getMessagesFor(chatId);
              final lastMsg = remaining.isNotEmpty ? remaining.last : null;

              await _chatController.updateUserLastMessage(
                userId: chatId,
                lastMessage: lastMsg?.message ?? '',
                lastMessageTime: lastMsg?.timestamp ?? DateTime.now(),
              );
            }
          },
        );
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        MyPrint.printOnConsole("App is no longer active, stopping service.");
        _selfDestructService.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // UserModel userModel =
    //     DependencyInjection.authenticationProvider.userModel.get() ??
    //     UserModel();
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
                style: themeData.textTheme.labelSmall
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
                style: themeData.textTheme.labelSmall
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
                AppAssets.settings_icon,
                height: 26,
                width: 26,
                color: themeData.primaryColor,
              ),
              title: Text(
                'Settings',
                style: themeData.textTheme.labelSmall
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
          ],
        ),
      ),
    );
  }
}
