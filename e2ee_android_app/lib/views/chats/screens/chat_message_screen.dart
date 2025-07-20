import 'dart:convert';
import 'package:e2ee_android_app/backend/common/dependency_injection.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:e2ee_models_app/view/common/components/loading_widget.dart';
import 'package:http/http.dart' as http;
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';
import 'package:provider/provider.dart';

import '../../../backend/chats/chat_repository.dart';
import '../../../backend/chats/chats_controller.dart';
import '../../../backend/chats/chats_provider.dart';
import '../../../backend/common/app_state.dart';
import '../../../backend/notification/notification_service.dart';
import '../components/message_bubble.dart';
import 'chat_list_screen.dart';

class ChatMessageScreen extends StatefulWidget {
  final ChatUserModel user;

  const ChatMessageScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen>
    with TickerProviderStateMixin, MySafeState {
  // --- State & Controllers ---
  final TextEditingController _messageController = TextEditingController();
  late final ChatController _chatController;
  late final ChatProvider _chatProvider;
  late final AppState _appState;

  int _loadedMessages = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  final ChatRepository _chatRepository = ChatRepository();

  String currentUserId = '';
  String currentUserToken = '';
  String? opponentUserId;
  String? opponentUsername;

  // --- Animation ---
  late final AnimationController _iconAnimationController;
  late final AnimationController _widthAnimationController;
  late final Animation<double> _iconAnimation;
  late final Animation<double> _widthAnimation;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatController = ChatController(chatProvider: _chatProvider);

    _appState = context.read<AppState>();
    _appState.setCurrentChattingWithUserId(widget.user.id);

    opponentUserId = widget.user.id;
    opponentUsername = widget.user.name;

    _initializeAnimations();
    _messageController.addListener(_onTextChanged);
    _initializeChat();
  }

  void _scrollToBottom() {
    // We use a post-frame callback to ensure the ListView has been updated
    // before we try to scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initializeAnimations() {
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _widthAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _widthAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeChat() async {
    currentUserId =
        await SharedPrefManager().getString('current_user_id') ?? '';
    currentUserToken =
        await SharedPrefManager().getString(
          MySharedPreferenceVariables.authToken,
        ) ??
        '';

    _chatProvider.currentOpponent.set(value: widget.user, isNotify: false);

    await _loadInitialMessages();

    _scrollController.addListener(() {
      if (_scrollController.offset <=
              _scrollController.position.minScrollExtent + 10 &&
          !_isLoadingMore) {
        _loadMoreMessages();
      }
    });

    // Tell the repository to start listening for messages
    _chatRepository.initPusher(
      userId: currentUserId,
      token: currentUserToken,
      onMessageReceived: _handleIncomingMessage, // Provide the callback
    );
  }

  Future<void> _loadInitialMessages() async {
    await _chatController.loadMessagesToProvider(
      chatId: widget.user.id,
      limit: _pageSize,
      offset: _loadedMessages,
      currentUserId: currentUserId,
    );
    final fetchedCount = _chatProvider.getMessagesFor(widget.user.id).length;
    _loadedMessages = fetchedCount;
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  Future<void> _loadMoreMessages() async {
    _isLoadingMore = true;
    await _chatController.loadMessagesToProvider(
      chatId: widget.user.id,
      limit: _pageSize,
      offset: _loadedMessages,
      currentUserId: currentUserId,
      clear: false,
    );
    final fetchedCount = _chatProvider.getMessagesFor(widget.user.id).length;
    _loadedMessages = fetchedCount;
    if (mounted) setState(() {});
    _isLoadingMore = false;
  }

  Future<void> _handleIncomingMessage(dynamic data) async {
    final messageData = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
    if (!mounted) return;

    // 1. Ensure a unique message id
    String messageId = "";
    if (messageData.containsKey('id') && messageData['id'].toString().isNotEmpty) {
      messageId = messageData['id'].toString();
    } else {
      messageId = MyUtils.getNewId();
    }

    final senderId = messageData['sender_id']?.toString() ?? '';
    final receiverId = messageData['receiver_id']?.toString() ?? '';
    final text = messageData['message']?.toString() ?? '';
    final timeStr = messageData['timestamp']?.toString() ?? '';
    final isMe = senderId == currentUserId;
    final otherUserId = isMe ? receiverId : senderId;
    final time = DateTime.tryParse(timeStr) ?? DateTime.now();


    final msg = ChatMessageModel(
      id: messageId,
      senderId: senderId,
      message: text,
      timestamp: time,
      isMe: isMe,
      status: 'delivered',
    );

    await _chatController.saveMessageToHive(
      chatId: otherUserId,
      message: msg,
    );
    _chatProvider.addMessageFor(otherUserId, msg);
    _scrollToBottom();

    String senderName = messageData['sender_name']?.toString() ?? '';
    String senderUsername = messageData['sender_username']?.toString() ?? '';

    if (senderName.isEmpty) {
      final fetched = await _chatRepository.fetchChatUser(
        userId: senderId,
        token: currentUserToken,
      );
      if (fetched != null && fetched.name.isNotEmpty) {
        senderName = fetched.name;
      }
    }

    final displayName = senderName.isNotEmpty
        ? senderName
        : (senderUsername.isNotEmpty ? senderUsername : senderId);

    if (_appState.lifecycleState == AppLifecycleState.resumed) {
      if (_appState.currentChattingWithUserId != otherUserId) {

        _appState.showCustomNotification(displayName, "");
      }
    } else if (_appState.lifecycleState == AppLifecycleState.paused) {
      NotificationService().showSystemNotification(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        displayName,
        "",
      );
    }
  }


  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      if (!mounted) return;
      setState(() => _hasText = hasText);
      hasText
          ? _iconAnimationController.forward()
          : _iconAnimationController.reverse();
      hasText
          ? _widthAnimationController.forward()
          : _widthAnimationController.reverse();
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    // Optimistically update the UI
    final localMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      message: messageText,
      timestamp: DateTime.now(),
      isMe: true,
      status: 'sent',
    );

    _chatProvider.addMessageFor(widget.user.id, localMessage);
    _loadedMessages += 1;

    await _chatController.saveMessageToHive(
      chatId: widget.user.id,
      message: localMessage,
    );

    await _chatController.addUserToChatList(
      ChatUserModel(
        id: widget.user.id,
        name: widget.user.name,
        avatar: widget.user.avatar,
        lastMessage: localMessage.message,
        lastMessageTime: localMessage.timestamp.toIso8601String(),
        isOnline: widget.user.isOnline,
        unreadCount: 0,
      ),
    );

    _scrollToBottom();

    // The controller already correctly calls the repository
    final success = await _chatController.sendMessage(message: messageText);
    if (!success) {
      MyPrint.printOnConsole('Send failed');
      // Here you might want to update the message status to 'failed'
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _iconAnimationController.dispose();
    _widthAnimationController.dispose();
    // Tell the repository to clean up its connection
    _chatRepository.disposePusher();
    _appState.setCurrentChattingWithUserId(null);
    super.dispose();
  }

  void _startVoiceRecording() {
    MyPrint.printOnConsole('Starting voice recording...');
  }

  void _onButtonPressed() {
    if (_hasText) {
      _sendMessage();
    } else {
      _startVoiceRecording();
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildMediaOption(
                      icon: Icons.camera_alt,
                      title: 'Camera',
                      subtitle: 'Take a photo or video',
                      color: Color(0xFF4CAF50),
                      onTap: _openCamera,
                    ),
                    SizedBox(height: 16),
                    _buildMediaOption(
                      icon: Icons.photo_library,
                      title: 'Gallery',
                      subtitle: 'Choose from gallery',
                      color: Color(0xFF2196F3),
                      onTap: _openGallery,
                    ),
                    SizedBox(height: 16),
                    _buildMediaOption(
                      icon: Icons.description,
                      title: 'Document',
                      subtitle: 'Share a file',
                      color: Color(0xFFFF9800),
                      onTap: _openDocuments,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCamera() {
    MyPrint.printOnConsole('Opening camera...');
  }

  void _openGallery() {
    MyPrint.printOnConsole('Opening gallery...');
  }

  void _openDocuments() {
    MyPrint.printOnConsole('Opening document picker...');
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeData.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: themeData.colorScheme.onSurface,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFFE6A532),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      widget.user.avatar,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (widget.user.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.user.isOnline ? 'Online' : 'Last seen recently',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: themeData.colorScheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final msgList = chatProvider.getMessagesFor(widget.user.id);
                final isLoadingMore =
                    _isLoadingMore; // or chatProvider.isLoadingMore if you move it there

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  reverse: false,
                  // latest message at bottom
                  itemCount: msgList.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isLoadingMore && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(heightFactor: 1, child: LoadingWidget()),
                      );
                    }
                    final msgIndex = isLoadingMore ? index - 1 : index;
                    final message = msgList[msgIndex];
                    // You can also add showTime headers, etc., here if needed
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: themeData.colorScheme.surface),
            child: Row(
              children: [
                // Media attachment button
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.add, color: Colors.grey[600], size: 30),
                  onPressed: _showMediaOptions,
                ),
                SizedBox(width: 2),
                AnimatedBuilder(
                  animation: _widthAnimation,
                  builder: (context, child) {
                    final baseWidth =
                        MediaQuery.of(context).size.width - 32 - 44 - 44 - 16;
                    final compactWidth = baseWidth * 1;
                    final expandedWidth = baseWidth;

                    final currentWidth =
                        compactWidth +
                        (_widthAnimation.value *
                            (expandedWidth - compactWidth));

                    return SizedBox(
                      height: 50,
                      width: currentWidth,
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(
                              color: themeData.colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              CupertinoIcons.flame_fill,
                              color: themeData.primaryColor,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        onSubmitted: (_) => _hasText ? _sendMessage() : null,
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(0xFFE6A532),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: AnimatedBuilder(
                    animation: _iconAnimation,
                    builder: (context, child) {
                      return IconButton(
                        icon: AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child:
                              _hasText
                                  ? Icon(
                                    Icons.send,
                                    key: ValueKey('send'),
                                    color: Colors.white,
                                    size: 20,
                                  )
                                  : Icon(
                                    Icons.mic,
                                    key: ValueKey('mic'),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                        ),
                        onPressed: _onButtonPressed,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
