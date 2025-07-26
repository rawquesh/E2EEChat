import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:e2ee_models_app/view/common/components/loading_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../backend/chats/chats_controller.dart';
import '../../../backend/chats/chats_provider.dart';
import '../../../backend/common/app_state.dart';
import '../../../configs/constants.dart';
import '../components/message_bubble.dart';

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
    _chatProvider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    // This method listens for the specific self-destruct event
    final lastDeleted = _chatProvider.lastDeletedMessages;
    if (lastDeleted != null && lastDeleted.chatId == widget.user.id) {
      MyPrint.printOnConsole(
        "[Real-time] Detected self-destruct for this chat. Reloading messages.",
      );

      // Reset the pagination counter and reload messages from scratch
      if (mounted) {
        setState(() {
          _loadedMessages = 0;
        });
        _loadInitialMessages();
      }

      _chatProvider.clearLastDeletedEvent();
    }
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

    // ✨ Issue 2 Fix: Clear unread count when entering the chat
    await _chatController.clearUnreadCount(widget.user.id);

    await _loadInitialMessages();

    _scrollController.addListener(() {
      if (_scrollController.offset <=
              _scrollController.position.minScrollExtent + 10 &&
          !_isLoadingMore) {
        _loadMoreMessages();
      }
    });

    // ✨ Issue 1 Fix: Removed Pusher initialization from this screen.
    // The global handler in main_screen.dart will manage all incoming messages.
  }

  Future<void> _loadInitialMessages() async {
    await _chatController.loadMessagesToProvider(
      chatId: widget.user.id,
      limit: _pageSize,
      offset: _loadedMessages,
      currentUserId: currentUserId,
      clear: true,
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

  void _sendMessage(String msgText) async {
    //final messageText = _messageController.text.trim();
    final messageText = msgText;
    if (messageText.isEmpty) return;

    //_messageController.clear();

    // Optimistically update the UI

    DateTime destructTimestamp = DateTime.now().add(
      Duration(minutes: selectedTimeForDestruct),
    );
    if (selectedTimeForDestruct == 0) {
      destructTimestamp = DateTime.now().add(Duration(days: 365 * 100));
    }

    final localMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      message: messageText,
      timestamp: DateTime.now(),
      isMe: true,
      status: 'sent',
      destructTimestamp: destructTimestamp,
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
    final success = await _chatController.sendMessage(
      message: messageText,
      destructTimer: selectedTimeForDestruct,
    );
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
    // ✨ Issue 1 Fix: Removed Pusher disposal call.
    _appState.setCurrentChattingWithUserId(null);
    _chatProvider.removeListener(_onProviderChange);
    super.dispose();
  }

  void _startVoiceRecording() {
    showAudioDialog(context, (base64Audio) {
      print("Send this to API or chat: $base64Audio");
      _sendMessage("$audioTypeChat$base64Audio");
    });
  }

  void _onButtonPressed() {
    if (_hasText) {
      _sendMessage(_messageController.text.trim());
      _messageController.clear();
    } else {
      _startVoiceRecording();
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat'),
        content: const Text('Remove all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _chatController.clearChat(widget.user.id);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete chat'),
        content: const Text('Delete this chat room and all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _chatController.deleteChat(widget.user.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    requestStoragePermission(true, true);
  }

  void _openGallery() {
    requestStoragePermission(false, true);
  }

  void _openDocuments() {
    pickAnyFile();
  }

  Future<void> pickAnyFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final filePath = result.files.first.path;
      Uint8List? fileBytes = await File(filePath!).readAsBytes();

      if (fileBytes != null) {
        print("File bytes: ${fileBytes}");
        _sendMessage("$docTypeChat${base64Encode(fileBytes)}");
      } else {
        print("File bytes are null (possibly picked from path, not memory)");
      }
    }
  }

  void showAudioDialog(
    BuildContext context,
    Function(String base64Audio) onSend,
  ) {
    final record = AudioRecorder();
    String? audioPath;
    bool isRecording = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> startRecording() async {
              if (await record.hasPermission()) {
                final dir = await getTemporaryDirectory();
                audioPath =
                    '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
                await record.start(const RecordConfig(), path: audioPath!);
                setState(() {
                  isRecording = true;
                });
              }
            }

            Future<void> stopRecording() async {
              await record.stop();
              setState(() {
                isRecording = false;
              });
            }

            Future<void> sendAudio() async {
              if (audioPath != null) {
                final file = File(audioPath!);
                if (await file.exists()) {
                  final bytes = await file.readAsBytes();
                  final base64Audio = base64Encode(bytes);
                  onSend(base64Audio);
                }
              }
              Navigator.of(context).pop();
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                "Record Audio",
                style: TextStyle(color: Colors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRecording ? Icons.mic : Icons.mic_none,
                    color: isRecording ? Colors.red : Colors.black,
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isRecording ? 'Recording...' : 'Tap "Record" to start',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        isRecording ? stopRecording() : startRecording();
                      },
                      child: Text(isRecording ? 'Stop' : 'Record'),
                    ),

                    InkWell(
                      onTap: () async {
                        if (!isRecording && audioPath != null) {
                          await sendAudio();
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: !isRecording && audioPath != null
                              ? Colors.orange
                              : Colors.black.withOpacity(0.2),
                        ),
                        child: Center(child: Text("Send")),
                      ),
                    ),

                    /*ElevatedButton(
                      onPressed: (!isRecording && audioPath != null)
                          ? () async {
                        await sendAudio();
                      }
                          : null,
                      child: const Text('Send'),
                    ),*/
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> requestStoragePermission(bool isCamera, bool isImage) async {
    if (Platform.isAndroid) {
      if (Platform.isAndroid && Platform.version.compareTo('13') >= 0) {
        await [
          Permission.photos,
          Permission.audio,
          Permission.camera,
        ].request();
      } else {
        await [Permission.storage, Permission.camera].request();
      }
      //pickFile(isCamera,isImage);
      _showMediaPickerDialog(isCamera);
    }
  }

  /*Future<void> pickFile(bool isCamera,bool isImage) async {
    final picker = ImagePicker();
    late XFile? image;
    if(isCamera){
      if(isImage){
        image = await picker.pickImage(source: ImageSource.camera);
      }else{
        image = await picker.pickVideo(source: ImageSource.camera);
      }
    }else{
      if(isImage){
        image = await picker.pickImage(source: ImageSource.gallery);
      }else{
        image = await picker.pickVideo(source: ImageSource.gallery);
      }
    }

    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _fileName = image?.name;
        fileBytes = bytes;
        _sendMessage("$imageTypeChat${base64Encode(fileBytes!)}");
      });
    }
  }*/

  final ImagePicker _picker = ImagePicker();
  XFile? image;
  Uint8List? fileBytes;

  void _showMediaPickerDialog(bool isCamera) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              isCamera
                  ? ListTile(
                      leading: Icon(Icons.photo_camera, color: Colors.white),
                      title: Text(
                        "Capture Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final images = await _picker.pickImage(
                          source: ImageSource.camera,
                        );
                        setState(() {
                          image = images;
                          prepareForSendMessage(true);
                        });
                      },
                    )
                  : SizedBox(),
              isCamera
                  ? ListTile(
                      leading: Icon(Icons.videocam, color: Colors.white),
                      title: Text(
                        "Capture Video",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final video = await _picker.pickVideo(
                          source: ImageSource.camera,
                        );
                        setState(() {
                          image = video;
                          prepareForSendMessage(false);
                        });
                      },
                    )
                  : SizedBox(),
              !isCamera
                  ? ListTile(
                      leading: Icon(Icons.image, color: Colors.white),
                      title: Text(
                        "Choose Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final images = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        setState(() {
                          image = images;
                          prepareForSendMessage(true);
                        });
                      },
                    )
                  : SizedBox(),
              !isCamera
                  ? ListTile(
                      leading: Icon(Icons.video_library, color: Colors.white),
                      title: Text(
                        "Choose Video",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        final video = await _picker.pickVideo(
                          source: ImageSource.gallery,
                        );
                        setState(() {
                          image = video;
                          prepareForSendMessage(false);
                        });
                      },
                    )
                  : SizedBox(),
            ],
          ),
        );
      },
    );
  }

  prepareForSendMessage(bool isImage) async {
    if (image != null) {
      final Uint8List bytes = await image!.readAsBytes();
      setState(() {
        fileBytes = bytes;
        if (isImage) {
          _sendMessage("$imageTypeChat${base64Encode(fileBytes!)}");
        } else {
          _sendMessage("$videoTypeChat${base64Encode(fileBytes!)}");
        }
      });
    }
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: themeData.colorScheme.onSurface),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearChatDialog();
              } else if (value == 'delete') {
                _showDeleteChatDialog();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
              PopupMenuItem(value: 'delete', child: Text('Delete Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final msgList = chatProvider.getMessagesFor(widget.user.id);
                final isLoadingMore = _isLoadingMore;

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
                          suffixIcon: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  CupertinoIcons.flame_fill,
                                  color: themeData.primaryColor,
                                ),
                                onPressed: () async {
                                  final selectedTime =
                                      await showTimeSelectionDialog(context);
                                  if (selectedTime != null) {
                                    print(
                                      "User selected: $selectedTimeForDestruct",
                                    );
                                  }
                                },
                              ),

                              selectedTimeForDestruct == 0
                                  ? SizedBox()
                                  : InkWell(
                                      onTap: () async {
                                        final selectedTime =
                                            await showTimeSelectionDialog(
                                              context,
                                            );
                                        if (selectedTime != null) {
                                          print(
                                            "User selected: $selectedTimeForDestruct",
                                          );
                                        }
                                      },
                                      child: Container(
                                        height: 15,
                                        width: 15,
                                        margin: EdgeInsets.only(top: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "$selectedTimeForDestruct",
                                            style: TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        onSubmitted: (_) {
                          _hasText
                              ? _sendMessage(_messageController.text.trim())
                              : null;
                          _messageController.clear();
                        },
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
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
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

  int selectedTimeForDestruct = 0;

  Future<int?> showTimeSelectionDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Select time for destroy message',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [0, 5, 10, 15].map((time) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: InkWell(
                  onTap: () {
                    selectedTimeForDestruct = time;
                    Navigator.pop(context, time);
                    setState(() {});
                  },
                  child: Row(
                    children: [
                      Container(
                        height: 15,
                        width: 15,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.circular(3),
                          color: selectedTimeForDestruct == time
                              ? Colors.black
                              : Colors.transparent,
                        ),
                      ),
                      SizedBox(width: 7),
                      Text(
                        time == 0 ? "None" : 'Destroy message after $time min',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
                /*child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, time),
                  child: Text('After $time min, msg will be destroy'),
                ),*/
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
