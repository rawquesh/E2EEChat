import 'dart:convert';

import 'package:e2ee_android_app/backend/webrtc/call_provider.dart';
import 'package:e2ee_android_app/constants/app_constants.dart';
import 'package:e2ee_android_app/navigation/navigation_arguments.dart';
import 'package:e2ee_android_app/styles/font_manager.dart';
import 'package:e2ee_android_app/managers/battery_manager.dart';
import 'package:e2ee_android_app/helpers/encryption_helper.dart';
import 'package:e2ee_android_app/pages/calls/calls_screen.dart';
import 'package:e2ee_android_app/pages/chats/chat_list_screen.dart';
import 'package:e2ee_android_app/pages/files_and_media/files_media_screen.dart';
import 'package:e2ee_android_app/pages/settings/settings_screen.dart';
import 'package:e2ee_android_app/navigation/navigation_operation_parameters.dart';
import 'package:e2ee_android_app/navigation/navigation_type.dart';
import 'package:e2ee_android_app/models/chats/chat_message_model.dart';
import 'package:e2ee_android_app/models/chats/chat_user_model.dart';
import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:e2ee_android_app/utils/my_safe_state.dart';
import 'package:e2ee_android_app/utils/my_utils.dart';
import 'package:e2ee_android_app/managers/secure_storage_manager.dart';
import 'package:e2ee_android_app/managers/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

import 'package:e2ee_android_app/backend/chats/chat_repository.dart';
import 'package:e2ee_android_app/backend/chats/chats_controller.dart';
import 'package:e2ee_android_app/backend/chats/chats_provider.dart';
import 'package:e2ee_android_app/backend/common/app_state.dart';
// import 'package:e2ee_android_app/backend/common/dependency_injection.dart';
import 'package:e2ee_android_app/backend/navigation/navigation_controller.dart';
import 'package:e2ee_android_app/backend/self_destruct/self_destruct_service.dart';
import 'package:e2ee_android_app/pages/components/flashy_tab_bar.dart';
import 'package:e2ee_android_app/pages/tab_state.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = "/MainScreen";

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin, MySafeState, WidgetsBindingObserver {
  int _currentIndex = 0;
  late final ChatRepository _chatRepository;
  late final ChatProvider _chatProvider;
  late final ChatController _chatController;
  late final AppState _appState;
  late CallProvider callProvider;
  final SelfDestructService _selfDestructService = SelfDestructService();
  bool _isCallDialogShowing = false;

  String _currentUserId = '';
  String _currentUserToken = '';

  final List<Widget> _screens = [ChatListScreen(), CallsScreen(), FilesMediaScreen(), SettingsScreen()];

  Future<void> _initializeSocket() async {
    callProvider = context.read<CallProvider>();
    _currentUserId = await SharedPrefManager().getString(MySharedPreferenceVariables.currentUserId) ?? '';
    MyPrint.printOnConsole('userId: $_currentUserId');
    _currentUserToken = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken) ?? '';

    MyPrint.printOnConsole("auth_token: ${_currentUserToken}");

    _chatRepository.initPusher(userId: _currentUserId, token: _currentUserToken, onMessageReceived: _handleIncomingMessage);

    MyPrint.printOnConsole('[PUSHER REPO] Pusher initialized for user: $_currentUserId, token: $_currentUserToken');

    // Fetch any messages that arrived while the app was offline
    await _fetchPendingMessages();

    callProvider.initController(userId: _currentUserId, token: _currentUserToken);
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
      final fetched = await _chatRepository.fetchChatUser(userId: callerId, token: _currentUserToken);
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
                // ✨ CORRECTED FLOW

                // 1. Get the user model first (you already do this)
                ChatUserModel? user = _chatProvider.chatUsers.getList().firstWhere(
                  (u) => u.id == callerId,
                  orElse: () => ChatUserModel(id: callerId),
                );
                // NOTE: You can combine your two user-fetching blocks into one here.

                // 2. Dismiss the dialog
                _dismissCallDialog();

                // 3. Navigate to the call screen immediately
                if (!mounted) return;
                NavigationController.navigateToVoiceCallScreen(
                  navigationOperationParameters: NavigationOperationParameters(
                    context: context,
                    navigationType: NavigationType.pushNamed,
                  ),
                  arguments: VoiceCallScreenNavigationArguments(user: user),
                );

                // 4. THEN accept the call in the background.
                // Use the provider's controller directly.
                context.read<CallProvider>().callController.acceptCall();
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

  /// Thin wrapper — Pusher events come in as raw dynamic data.
  void _handleIncomingMessage(dynamic data) async {
    MyPrint.printOnConsole("XXIncoming message data: $data");
    try {
      final payloadData = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
      await _processMessagePayload(payloadData);
    } catch (e) {
      MyPrint.printOnConsole("Error handling incoming message: $e");
    }
  }

  /// Fetches messages stored on the server while the app was offline and processes them.
  Future<void> _fetchPendingMessages() async {
    try {
      final pending = await _chatRepository.fetchPendingMessages(token: _currentUserToken);
      for (final payloadData in pending) {
        await _processMessagePayload(payloadData);
      }
    } catch (e) {
      MyPrint.printOnConsole("Error fetching pending messages: $e");
    }
  }

  /// Processes a single message payload — shared by both Pusher events and pending messages.
  Future<void> _processMessagePayload(Map<String, dynamic> payloadData) async {
    final senderId = payloadData['sender_id']?.toString() ?? '';
    if (senderId.isEmpty) return;

    final bool isMe = senderId == _currentUserId;
    if (isMe) return;

    var encryptedMessagePayload = payloadData['message'];
    Map<String, dynamic>? decryptedPayload = await EncryptionHelper().decryptMessagePayload(
      encryptedData: Map<String, dynamic>.from(encryptedMessagePayload),
      myUserId: _currentUserId,
    );

    if (decryptedPayload == null) {
      MyPrint.printOnConsole("Error: Failed to decrypt incoming message payload.");
      return;
    }

    ChatMessageData messageData = ChatMessageData.fromMap(decryptedPayload);

    final String messageType = payloadData['type']?.toString() ?? 'single';

    String chatId;
    String chatName;
    String chatAvatarUrl = messageData.avatar ?? '';
    List<String> receivers = [];

    if (messageType == 'group') {
      chatId = payloadData['group_id']?.toString() ?? '';
      chatName = payloadData['group_name']?.toString() ?? 'Group';
      if (payloadData['receivers'] != null) {
        receivers = List<String>.from(payloadData['receivers']);
      }
    } else {
      final receiverId = payloadData['receiver_id']?.toString() ?? '';
      chatId = isMe ? receiverId : senderId;
      chatName = decryptedPayload['nickname']?.toString() ?? 'Unknown User';
    }

    if (chatId.isEmpty) {
      MyPrint.printOnConsole("Error: Could not determine chatId from incoming message.");
      return;
    }

    if (messageData.type != ChatMessageType.Text.name) {
      String path = await MyUtils.saveFileToDevice(base64Decode(messageData.base64String), messageData.fileName);
      messageData.base64String = path;
    }

    final time = DateTime.tryParse(payloadData['timestamp']?.toString() ?? '') ?? DateTime.now();
    final messageId = payloadData['id']?.toString() ?? MyUtils.getNewId();
    final tempDestructTimer = decryptedPayload['destructTimer'] as int? ?? 0;

    final chatMessage = ChatMessageModel(
      id: messageId,
      senderId: senderId,
      message: messageData,
      timestamp: time,
      isMe: isMe,
      status: 'delivered',
      destructTimestamp: DateTime.now().add(Duration(seconds: tempDestructTimer)),
    );

    _chatProvider.addMessageFor(chatId, chatMessage);
    await _chatController.saveMessageToHive(chatId: chatId, message: chatMessage);

    List<ChatUserModel> users = List<ChatUserModel>.from(_chatProvider.chatUsers.getList());
    int index = users.indexWhere((u) => u.id == chatId);
    ChatUserModel chatListItem;

    String lastMessageSnippet = messageData.type == ChatMessageType.Text.name ? messageData.text : messageData.type;
    if (messageType == 'group' && !isMe) {
      lastMessageSnippet = "${decryptedPayload['nickname']}: $lastMessageSnippet";
    }

    if (index == -1) {
      chatListItem = ChatUserModel(
        id: chatId,
        nickname: chatName,
        username: messageType == 'group' ? chatId : (decryptedPayload['username'] ?? ''),
        avatar: chatAvatarUrl,
        lastMessage: lastMessageSnippet,
        lastMessageTime: time.toIso8601String(),
        unreadCount: isMe ? 0 : 1,
        type: messageType == 'group' ? ChatRoomType.Group : ChatRoomType.Single,
        receivers: receivers,
        groupName: messageType == 'group' ? chatName : null,
      );
    } else {
      chatListItem = users[index];
      chatListItem.nickname = chatName;
      chatListItem.avatar = chatAvatarUrl;
      chatListItem.lastMessage = lastMessageSnippet;
      chatListItem.lastMessageTime = time.toIso8601String();
      if (!isMe && _appState.currentChattingWithUserId != chatId) {
        chatListItem.unreadCount++;
      }
    }

    await _chatController.addUserToChatList(chatListItem);

    if (!isMe) {
      final notificationTitle = messageType == 'group' ? chatName : (decryptedPayload['nickname'] ?? 'New Message');
      final notificationBody = messageType == 'group' ? lastMessageSnippet : messageData.text;

      if (_appState.lifecycleState == AppLifecycleState.resumed) {
        if (_appState.currentChattingWithUserId != chatId) {
          _appState.showCustomNotification('New message from $notificationTitle', notificationBody);
        }
      }
    }
  }

  /// Checks if battery optimization is enabled and if we should show the dialog.
  Future<void> _checkAndShowBatteryOptimizationDialog() async {
    // We use a flag to ensure we only ask the user once.
    bool alreadyRequested =
        (await SharedPrefManager().getBool(MySharedPreferenceVariables.batteryOptimizationRequested)) ?? false;

    if (alreadyRequested) {
      return;
    }

    bool? isBatteryOptimizationDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;

    if (isBatteryOptimizationDisabled == false) {
      if (mounted) {
        // Ensure the widget is still in the tree
        showDialog(
          context: context,
          barrierDismissible: false, // User must interact with the dialog
          builder: (BuildContext context) {
            return const BatteryOptimizationDialog();
          },
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowBatteryOptimizationDialog();
    });
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
          final messageData = lastMsg?.message ?? ChatMessageData(type: ChatMessageType.Text.name, text: '');

          await _chatController.updateUserLastMessage(
            userId: chatId,
            lastMessage: messageData.type == ChatMessageType.Text.name ? messageData.text : messageData.type,
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
              final messageData = lastMsg?.message ?? ChatMessageData(type: ChatMessageType.Text.name, text: '');

              await _chatController.updateUserLastMessage(
                userId: chatId,
                lastMessage: messageData.type == ChatMessageType.Text.name ? messageData.text : messageData.type,
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
              icon: Image.asset(AppAssets.chat_icon, height: 26, width: 26, color: themeData.primaryColor),
              title: Text(
                'Chats',
                style: themeData.textTheme.labelSmall
                    ?.copyWith(fontSize: 10, color: themeData.colorScheme.onSurface, fontWeight: FontWeight.bold)
                    .withEpilogue,
              ),
              activeColor: themeData.primaryColor,
              inactiveColor: themeData.primaryColor.withValues(alpha: 0.4),
            ),
            FlashyTabBarItem(
              icon: Image.asset(AppAssets.call_icon, height: 26, width: 26, color: themeData.primaryColor),
              title: Text(
                'Calls & Contacts',
                style: themeData.textTheme.labelSmall
                    ?.copyWith(fontSize: 10, color: themeData.colorScheme.onSurface, fontWeight: FontWeight.bold)
                    .withEpilogue,
              ),
              activeColor: themeData.primaryColor,
              inactiveColor: themeData.primaryColor.withValues(alpha: 0.4),
            ),
            FlashyTabBarItem(
              icon: Image.asset(AppAssets.files_icon, height: 26, width: 26, color: themeData.primaryColor),
              title: Text(
                'Files & Media',
                style: themeData.textTheme.labelSmall
                    ?.copyWith(fontSize: 10, color: themeData.colorScheme.onSurface, fontWeight: FontWeight.bold)
                    .withEpilogue,
              ),
              activeColor: themeData.primaryColor,
              inactiveColor: themeData.primaryColor.withValues(alpha: 0.4),
            ),
            FlashyTabBarItem(
              icon: Image.asset(AppAssets.settings_icon, height: 26, width: 26, color: themeData.primaryColor),
              title: Text(
                'Settings',
                style: themeData.textTheme.labelSmall
                    ?.copyWith(fontSize: 10, color: themeData.colorScheme.onSurface, fontWeight: FontWeight.bold)
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
