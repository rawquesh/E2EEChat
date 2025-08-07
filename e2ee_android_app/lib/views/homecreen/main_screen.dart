import 'dart:convert';

import 'package:e2ee_android_app/backend/webrtc/call_controller.dart';
import 'package:e2ee_android_app/backend/webrtc/call_provider.dart';
import 'package:e2ee_android_app/configs/constants.dart';
import 'package:e2ee_android_app/configs/font_manager.dart';
import 'package:e2ee_android_app/utils/battery.dart';
import 'package:e2ee_android_app/utils/encryption_service.dart';
import 'package:e2ee_android_app/views/calls/screens/calls_screen.dart';
import 'package:e2ee_android_app/views/chats/screens/chat_list_screen.dart';
import 'package:e2ee_android_app/views/files_and_media/files_media_screen.dart';
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
import 'package:disable_battery_optimization/disable_battery_optimization.dart';

import '../../backend/chats/chat_repository.dart';
import '../../backend/chats/chats_controller.dart';
import '../../backend/chats/chats_provider.dart';
import '../../backend/common/app_state.dart';
// import '../../backend/common/dependency_injection.dart';
import '../../backend/navigation/navigation_arguments.dart';
import '../../backend/navigation/navigation_controller.dart';
import '../../backend/self_destruct/self_destruct_service.dart';
import '../common/components/flashy_tab_bar.dart';
import '../tab_state.dart';

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
  late CallController callController;
  late CallProvider callProvider;
  final SelfDestructService _selfDestructService = SelfDestructService();
  bool _isCallDialogShowing = false;

  String _currentUserId = '';
  String _currentUserToken = '';

  final List<Widget> _screens = [ChatListScreen(), CallsScreen(), FilesMediaScreen(), SettingsScreen()];

  Future<void> _initializeSocket() async {
    callController = CallController();
    callProvider = context.read<CallProvider>();
    _currentUserId = await SharedPrefManager().getString(MySharedPreferenceVariables.currentUserId) ?? '';
    MyPrint.printOnConsole('userId: $_currentUserId');
    _currentUserToken = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken) ?? '';

    MyPrint.printOnConsole("auth_token: ${_currentUserToken}");

    _chatRepository.initPusher(userId: _currentUserId, token: _currentUserToken, onMessageReceived: _handleIncomingMessage);

    MyPrint.printOnConsole('[PUSHER REPO] Pusher initialized for user: $_currentUserId, token: $_currentUserToken');

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

  void _handleIncomingMessage(dynamic data) async {
    MyPrint.printOnConsole("XXIncoming message data: $data");
    try {
      final payloadData = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

      final senderId = payloadData['sender_id']?.toString() ?? '';
      if (senderId.isEmpty) return; // Ignore invalid messages

      final bool isMe = senderId == _currentUserId;
      if (isMe) return;

      var encryptedMessagePayload = payloadData['message'];
      Map<String, dynamic>? decryptedPayload = await EncryptionService().decryptMessagePayload(
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
      // We get the avatar URL from the messageData itself
      String chatAvatarUrl = messageData.avatar ?? '';
      List<String> receivers = [];

      if (messageType == 'group') {
        chatId = payloadData['group_id']?.toString() ?? '';
        chatName = payloadData['group_name']?.toString() ?? 'Group';
        if (payloadData['receivers'] != null) {
          receivers = List<String>.from(payloadData['receivers']);
        }
      } else {
        // 'single'
        final receiverId = payloadData['receiver_id']?.toString() ?? '';
        chatId = isMe ? receiverId : senderId;
        chatName = decryptedPayload['nickname']?.toString() ?? 'Unknown User';
      }

      if (chatId.isEmpty) {
        MyPrint.printOnConsole("Error: Could not determine chatId from incoming message.");
        return;
      }

      // Handle file paths for non-text messages
      if (messageData.type != ChatMessageType.Text.name) {
        String path = await MyUtils.saveFileToDevice(base64Decode(messageData.base64String), messageData.fileName);
        messageData.base64String = path;
      }

      // Create the core message model. messageData already contains the avatar.
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

      // Storing the message (including the avatar) in the provider and local database
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
        // Create new entry using the fetched avatar URL
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
        // Update existing entry with the new avatar URL
        chatListItem = users[index];
        chatListItem.nickname = chatName;
        chatListItem.avatar = chatAvatarUrl; // Update the avatar URL here
        chatListItem.lastMessage = lastMessageSnippet;
        chatListItem.lastMessageTime = time.toIso8601String();
        if (!isMe && _appState.currentChattingWithUserId != chatId) {
          chatListItem.unreadCount++;
        }
      }

      // This updates the chat list screen's data
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
    } catch (e, s) {
      MyPrint.printOnConsole("Error in _handleIncomingMessage: $e\n$s");
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
