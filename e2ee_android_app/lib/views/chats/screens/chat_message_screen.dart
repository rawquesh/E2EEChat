import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  // Animation controllers
  late AnimationController _iconAnimationController;
  late AnimationController _widthAnimationController;
  late Animation<double> _iconAnimation;
  late Animation<double> _widthAnimation;

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    messages = ChatData.getMessagesForUser(widget.user.id);

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

    // Listen to text changes
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _iconAnimationController.dispose();
    _widthAnimationController.dispose();
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

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: 'me',
            message: _messageController.text.trim(),
            timestamp: DateTime.now(),
            isMe: true,
            status: MessageStatus.sent,
          ),
        );
      });
      _messageController.clear();
    }
  }

  void _startVoiceRecording() {
    // Implement voice recording logic here
    print('Starting voice recording...');
    // You can add voice recording functionality using packages like:
    // - flutter_sound
    // - record
    // - speech_to_text
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
                color: color.withValues(alpha: 0.1),
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
    // Implement camera functionality here
    print('Opening camera...');
    // You can use packages like:
    // - image_picker (for photos/videos)
    // - camera (for more control)
  }

  void _openGallery() {
    // Implement gallery functionality here
    print('Opening gallery...');
    // You can use packages like:
    // - image_picker
    // - photo_manager
  }

  void _openDocuments() {
    // Implement document picker functionality here
    print('Opening document picker...');
    // You can use packages like:
    // - file_picker
    // - document_file_save_plus
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
          // Remove this line to eliminate the border:
          // Container(height: 1, color: Colors.grey[200]),
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
                    final baseWidth =
                        MediaQuery.of(context).size.width -
                            32 -
                            44 -
                            44 -
                            16; // Total - padding - buttons - spacing
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
