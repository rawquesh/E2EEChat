import 'dart:convert';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:http/http.dart' as http;
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';

import '../components/message_bubble.dart';
import 'chat_list_screen.dart';

class ChatMessageScreen extends StatefulWidget {
  final ChatUser user;

  const ChatMessageScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen>
    with TickerProviderStateMixin, MySafeState {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> messages = [];
  PusherClient? _pusher;
  Channel? _channel;

  final String currentUserId = 'dee2fb8b-b5fa-42b7-9ebd-cd3412e3dff8';
  final String currentUserToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovLzE3Mi44Ni45Mi4xMzAuc3NsaXAuaW8vYXBpL2F1dGgvcmVnaXN0ZXIiLCJpYXQiOjE3NTI3ODg2ODIsImV4cCI6MTc1ODc4ODY4MiwibmJmIjoxNzUyNzg4NjgyLCJqdGkiOiJmWnhDMVRLcHdoeElFejlrIiwic3ViIjoiZGVlMmZiOGItYjVmYS00MmI3LTllYmQtY2QzNDEyZTNkZmY4IiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyIsInVzZXJuYW1lIjoidXNlcjEiLCJyb2xlIjpbXSwic2Vzc2lvbl90b2tlbiI6ImFkY2U0NTNhLWQyNWEtNDdmNi1iY2VmLTI1YTBkMGM2MTBmMiJ9.J84DB_ADRLwPLbiER6A-z028LkW8Av6gTRL6TrhpU9Q';
  String? opponentUserId = "b2dbf505-cf02-4f50-abf4-ff644d0bbbf5";
  String? opponentUsername;

  // API Base URL
  static const String API_BASE = 'https://172.86.92.130.sslip.io';

  // Animation controllers
  late AnimationController _iconAnimationController;
  late AnimationController _widthAnimationController;
  late Animation<double> _iconAnimation;
  late Animation<double> _widthAnimation;

  bool _hasText = false;
  bool _isLoadingOpponent = false;

  @override
  void initState() {
    super.initState();
    // Initialize with empty messages for testing
    messages = [];

    // Initialize animation controllers
    _iconAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _widthAnimationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );

    // Create animations
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

    _messageController.addListener(_onTextChanged);

    // Hardcoded opponent username for testing
    _setOpponent('user2');
  }

  void _initPusher() {
    // Configure Pusher options
    final options = PusherOptions(
      key: 'sip6lkxyrl3d0um6vbv9',
      cluster: 'mt1',
      host: '172.86.92.130.sslip.io',
      wsPort: 8080,
      wssPort: 443,
      encrypted: false,
      authOptions: PusherAuthOptions(
        'https://172.86.92.130.sslip.io/broadcasting/auth',
        headers: {
          'Authorization': 'Bearer $currentUserToken',
        },
      ),
      // enableLogging: true,
      // autoConnect: false,
    );

    // Initialize the client
    _pusher = PusherClient(options: options);

    // Set up connection event handlers
    _pusher!.onConnectionEstablished((data) {
      MyPrint.printOnConsole('[PUSHER SOCKET] Connection established - socket-id: ${_pusher!.socketId}');
    });

    _pusher!.onConnectionError((error) {
      MyPrint.printOnConsole('[PUSHER SOCKET] Connection error: $error');
    });

    _pusher!.onError((error) {
      MyPrint.printOnConsole('[PUSHER SOCKET] Error: $error');
    });

    _pusher!.onDisconnected((data) {
      MyPrint.printOnConsole('[PUSHER SOCKET] Disconnected: $data');
    });

    // Connect to Pusher
    _pusher!.connect();

    final channelName = 'private-chat.$currentUserId';
    MyPrint.printOnConsole('[PUSHER DEBUG] Subscribing to channel: $channelName');


    _channel = _pusher!.channel(channelName);

    // Listen for events on the channel
    _channel!.bind('MessageSent', (data) {
      MyPrint.printOnConsole('[PUSHER SOCKET] Received MessageSent event: $data');
      if (data != null) {
        _handleIncomingMessage(data);
      }
    });
  }

  void _handleIncomingMessage(dynamic data) {
    MyPrint.printOnConsole('[CHAT DEBUG] Received message event data: $data');
    try {
      // Parse the data if it's a string
      final messageData = data is String ? jsonDecode(data) : data;

      setState(() {
        messages.add(ChatMessage(
          id: messageData['id'].toString(),
          senderId: messageData['sender_id'],
          message: messageData['message'],
          timestamp: DateTime.tryParse(messageData['timestamp'] ?? '') ?? DateTime.now(),
          isMe: messageData['sender_id'] == currentUserId,
          status: MessageStatus.delivered,
        ));
      });
    } catch (e) {
      MyPrint.printOnConsole('[PUSHER SOCKET] Error parsing message data: $e');
    }
  }

  void _disposePusher() {
    try {
      _channel?.unbind('MessageSent');
      _channel?.unsubscribe();
      _pusher?.disconnect();
    } catch (e) {
      MyPrint.printOnConsole('[PUSHER SOCKET] Error disposing pusher: $e');
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _iconAnimationController.dispose();
    _widthAnimationController.dispose();
    _disposePusher();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });

      if (hasText) {
        _iconAnimationController.forward();
        _widthAnimationController.forward();
      } else {
        _iconAnimationController.reverse();
        _widthAnimationController.reverse();
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Add temporary message (optimistic UI)
    setState(() {
      messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUserId,
        message: messageText,
        timestamp: DateTime.now(),
        isMe: true,
        status: MessageStatus.sent,
      ));
    });

    // Send to backend
    final url = Uri.parse('https://172.86.92.130.sslip.io/api/chat/send');
    final body = jsonEncode({
      "chat_id": opponentUserId,
      "message": messageText,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $currentUserToken",
        },
        body: body,
      );
      if (response.statusCode == 200) {
        MyPrint.printOnConsole('Message sent!');
      } else {
        MyPrint.printOnConsole('Send failed: ${response.body}');
      }
    } catch (e) {
      MyPrint.printOnConsole('Send error: $e');
    }
  }

  Future<void> _setOpponent(String username) async {
    if (_isLoadingOpponent) return;

    setState(() {
      _isLoadingOpponent = true;
    });

    try {
      final url = Uri.parse('$API_BASE/api/chat/getopponent');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentUserToken',
        },
        body: jsonEncode({
          'username': username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          opponentUserId = data['id'];
          opponentUsername = data['username'];
        });

        MyPrint.printOnConsole('Opponent set: $opponentUsername ($opponentUserId)');

        // Initialize Pusher connection after setting opponent
        _initPusher();
      } else {
        MyPrint.printOnConsole('Failed to get opponent: ${response.body}');
      }
    } catch (e) {
      MyPrint.printOnConsole('Error setting opponent: $e');
    } finally {
      setState(() {
        _isLoadingOpponent = false;
      });
    }
  }

  void _changeOpponent() {
    showDialog(
      context: context,
      builder: (context) {
        final usernameController = TextEditingController();
        return AlertDialog(
          title: Text('Enter Username'),
          content: TextField(
            controller: usernameController,
            decoration: InputDecoration(
              hintText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final username = usernameController.text.trim();
                if (username.isNotEmpty) {
                  Navigator.pop(context);
                  _disposePusher(); // Dispose current connection
                  _setOpponent(username); // Set new opponent
                }
              },
              child: Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  void _sendCustomMessage(dynamic messageData) async {
    if (opponentUserId == null) return;

    final url = Uri.parse('$API_BASE/api/send-message');
    final body = jsonEncode({
      "sender_id": currentUserId,
      "receiver_id": opponentUserId,
      "message": messageData, // Can be string, int, or JSON structure
    });

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $currentUserToken",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        MyPrint.printOnConsole('Custom message sent successfully!');
      } else {
        MyPrint.printOnConsole('Send failed: ${response.body}');
      }
    } catch (e) {
      MyPrint.printOnConsole('Send error: $e');
    }
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
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeData.colorScheme.surface,
            ),
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
                    final baseWidth = MediaQuery.of(context).size.width -
                        32 -
                        44 -
                        44 -
                        16;
                    final compactWidth = baseWidth * 1;
                    final expandedWidth = baseWidth;

                    final currentWidth = compactWidth +
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
                          child: _hasText
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
