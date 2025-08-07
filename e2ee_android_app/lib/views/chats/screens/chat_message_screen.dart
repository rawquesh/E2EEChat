import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:e2ee_models_app/backend/navigation/navigation_operation_perameters.dart';
import 'package:e2ee_models_app/backend/navigation/navigation_type.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/configs/styles.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';
import 'package:e2ee_models_app/view/common/components/common_cachednetwork_image.dart';
import 'package:e2ee_models_app/view/common/components/loading_widget.dart';
import 'package:e2ee_models_app/view/common/components/modal_progress_hud.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../../backend/authentication/authentication_provider.dart';
import '../../../backend/chats/chats_controller.dart';
import '../../../backend/chats/chats_provider.dart';
import '../../../backend/common/app_state.dart';
import '../../../backend/files_and_media/media_compression.dart';
import '../../../backend/navigation/navigation_arguments.dart';
import '../../../backend/navigation/navigation_controller.dart';
import '../../../backend/webrtc/call_provider.dart';
import '../../../configs/constants.dart';
import '../components/group_details_bottom_sheet.dart';
import '../components/message_bubble.dart';

class ChatMessageScreen extends StatefulWidget {
  final ChatUserModel chatInfo;

  const ChatMessageScreen({Key? key, required this.chatInfo}) : super(key: key);

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> with TickerProviderStateMixin, MySafeState {
  // --- State & Controllers ---
  final TextEditingController _messageController = TextEditingController();
  late final ChatController _chatController;
  late final ChatProvider _chatProvider;
  late final AppState _appState;
  String? profilePicPath = '';
  bool isLoading = false;

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
    MyPrint.printOnConsole(widget.chatInfo.toMap()..putIfAbsent("UserX", () => "UserX"));

    super.initState();
    _chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthenticationProvider>();
    _chatController = ChatController(chatProvider: _chatProvider, authenticationProvider: authProvider);

    _appState = context.read<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState.setCurrentChattingWithUserId(widget.chatInfo.id);
    });

    opponentUserId = widget.chatInfo.id;
    opponentUsername = widget.chatInfo.nickname;

    _initializeAnimations();
    _messageController.addListener(_onTextChanged);
    _initializeChat();
    _chatProvider.addListener(_onProviderChange);
  }

  void _onProviderChange() {
    // This method listens for the specific self-destruct event
    final lastDeleted = _chatProvider.lastDeletedMessages;
    if (lastDeleted != null && lastDeleted.chatId == widget.chatInfo.id) {
      MyPrint.printOnConsole("[Real-time] Detected self-destruct for this chat. Reloading messages.");

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 1000), curve: Curves.easeOut);
        }
      });
    });
  }

  void _showGroupDetails() {
    if (widget.chatInfo.type == ChatRoomType.Group) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => GroupDetailsBottomSheet(groupInfo: widget.chatInfo),
      );
    }
  }

  void _initializeAnimations() {
    _iconAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _widthAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _iconAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeInOut));
    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _widthAnimationController, curve: Curves.easeInOut));
  }

  Future<void> getProfilePicture() async {
    final authProvider = context.read<AuthenticationProvider>();
    final user = authProvider.userModel.get();
    if (user != null) {
      profilePicPath = user.profilePicture;
      if (profilePicPath == null || profilePicPath!.isEmpty) {
        profilePicPath = await SharedPrefManager().getString(MySharedPreferenceVariables.avatarUrl);
      }
      if (profilePicPath == null || profilePicPath!.isEmpty) {
        profilePicPath = 'default_avatar.png'; // Fallback to a default avatar
      }
    }
  }

  Future<void> _initializeChat() async {
    currentUserId = await SharedPrefManager().getString(MySharedPreferenceVariables.currentUserId) ?? '';
    currentUserToken = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken) ?? '';

    _chatProvider.currentOpponent.set(value: widget.chatInfo, isNotify: false);

    await _chatController.clearUnreadCount(widget.chatInfo.id);

    await _loadInitialMessages();

    _scrollController.addListener(() {
      if (_scrollController.offset <= _scrollController.position.minScrollExtent + 10 && !_isLoadingMore) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadInitialMessages() async {
    await _chatController.loadMessagesToProvider(chatId: widget.chatInfo.id, limit: _pageSize, offset: _loadedMessages, currentUserId: currentUserId, clear: true);
    final fetchedCount = _chatProvider.getMessagesFor(widget.chatInfo.id).length;
    _loadedMessages = fetchedCount;
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  Future<void> _loadMoreMessages() async {
    _isLoadingMore = true;
    await _chatController.loadMessagesToProvider(chatId: widget.chatInfo.id, limit: _pageSize, offset: _loadedMessages, currentUserId: currentUserId, clear: false);
    final fetchedCount = _chatProvider.getMessagesFor(widget.chatInfo.id).length;
    _loadedMessages = fetchedCount;
    if (mounted) setState(() {});
    _isLoadingMore = false;
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      if (!mounted) return;
      setState(() => _hasText = hasText);
      hasText ? _iconAnimationController.forward() : _iconAnimationController.reverse();
      hasText ? _widthAnimationController.forward() : _widthAnimationController.reverse();
    }
  }

  void _sendMessage({required ChatMessageType type, String? textMessage, Uint8List? fileBytes, String? fileName}) async {
    if (type != ChatMessageType.Text && fileBytes == null) return;
    if (type == ChatMessageType.Text && (textMessage == null || textMessage.isEmpty)) return;

    MyPrint.printOnConsole('XXData: textMessage: $textMessage, fileBytes: ${fileBytes?.length}, fileName: $fileName type: ${type}');

    _messageController.clear();

    DateTime destructTimestamp = selectedTimeForDestruct == 0 ? DateTime.now().add(const Duration(days: 365 * 100)) : DateTime.now().add(Duration(minutes: selectedTimeForDestruct));
    final authProvider = context.read<AuthenticationProvider>();
    final sharedAvatar = await SharedPrefManager().getString(MySharedPreferenceVariables.avatarUrl);
    final avatarUrl = sharedAvatar?.isNotEmpty == true ? sharedAvatar! : authProvider.userModel.get()?.profilePicture ?? '';
    MyPrint.printOnConsole('chat message screen Avatar url: $avatarUrl');

    var chatMessageData = ChatMessageData(
      type: type.name,
      text: textMessage ?? "",
      base64String: base64Encode(fileBytes ?? Uint8List(0)),
      fileName: fileName ?? '',
      senderNickname: opponentUsername,
      avatar: avatarUrl,
    );

    _chatController.sendMessage(message: chatMessageData, destructTimer: selectedTimeForDestruct).then((success) {
      if (!success) {
        MyPrint.printOnConsole('[SEND DEBUG] Failed to send message.');
        return;
      }
      MyPrint.printOnConsole('[SEND DEBUG] Message sent successfully.');
    });

    var newChatMessageData = ChatMessageData(type: type.name, text: textMessage ?? "", base64String: "", fileName: fileName ?? '', avatar: avatarUrl);

    if (type != ChatMessageType.Text && fileBytes != null && fileName != null) {
      String path = await MyUtils.saveFileToDevice(fileBytes, fileName);
      newChatMessageData.base64String = path;
    }

    final localMessage = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      message: newChatMessageData,
      timestamp: DateTime.now(),
      isMe: true,
      status: 'sent',
      // Optimistically set status to 'sent'
      destructTimestamp: destructTimestamp,
    );

    await _saveLocalMessage(localMessage: localMessage);
  }

  Future<void> _saveLocalMessage({required ChatMessageModel localMessage}) async {
    _chatProvider.addMessageFor(widget.chatInfo.id, localMessage);
    _loadedMessages += 1;

    await _chatController.saveMessageToHive(chatId: widget.chatInfo.id, message: localMessage);

    var text2 = localMessage.message.text;
    if (text2.isEmpty) {
      text2 = localMessage.message.type;
    }

    await _chatController.addUserToChatList(
      ChatUserModel(
        id: widget.chatInfo.id,
        nickname: widget.chatInfo.nickname,
        username: widget.chatInfo.username,
        avatar: widget.chatInfo.avatar,
        lastMessage: text2,
        lastMessageTime: localMessage.timestamp.toIso8601String(),
        isOnline: widget.chatInfo.isOnline,
        unreadCount: 0,
        groupName: widget.chatInfo.groupName,
        receivers: widget.chatInfo.receivers,
        type: widget.chatInfo.type,
      ),
    );

    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _iconAnimationController.dispose();
    _widthAnimationController.dispose();
    _appState.setCurrentChattingWithUserId(null);
    _chatProvider.removeListener(_onProviderChange);
    super.dispose();
  }

  void _startVoiceRecording() {
    showAudioDialog(context, (filePath) async {
      print("Send this to API or chat: $filePath");
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;
      _sendMessage(type: ChatMessageType.Audio, fileBytes: bytes, fileName: fileName);
    });
  }

  void _onButtonPressed() {
    if (_hasText) {
      _sendMessage(type: ChatMessageType.Text, textMessage: _messageController.text.trim());
      _messageController.clear();
    } else {
      _startVoiceRecording();
    }
    FocusScope.of(context).unfocus();
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat'),
        content: const Text('Remove all messages in this chat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _chatController.clearChat(widget.chatInfo.id);
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _chatController.deleteChat(widget.chatInfo.id);
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
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildMediaOption(icon: Icons.camera_alt, title: 'Camera', subtitle: 'Take a photo or video', color: Color(0xFF4CAF50), onTap: _openCamera),
                    SizedBox(height: 16),
                    _buildMediaOption(icon: Icons.photo_library, title: 'Gallery', subtitle: 'Choose from gallery', color: Color(0xFF2196F3), onTap: _openGallery),
                    SizedBox(height: 16),
                    _buildMediaOption(icon: Icons.description, title: 'Document', subtitle: 'Share a file', color: Color(0xFFFF9800), onTap: _openDocuments),
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

  Widget _buildMediaOption({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileBytes = await file.readAsBytes();
      _sendMessage(type: ChatMessageType.Doc, fileBytes: fileBytes, fileName: fileName);
    }
  }

  void showAudioDialog(BuildContext context, Function(String filePath) onSend) {
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
                audioPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
                  final fileName = audioPath!.split('/').last;
                  final filePath = await MyUtils.saveFileToDevice(bytes, fileName);
                  onSend(filePath);
                }
              }
              Navigator.of(context).pop();
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Record Audio", style: TextStyle(color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isRecording ? Icons.mic : Icons.mic_none, color: isRecording ? Colors.red : Colors.black, size: 48),
                  const SizedBox(height: 10),
                  Text(isRecording ? 'Recording...' : 'Tap "Record" to start', style: TextStyle(color: Colors.black)),
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
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), color: !isRecording && audioPath != null ? Styles.grey500 : Colors.black.withOpacity(0.2)),
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
        await [Permission.photos, Permission.audio, Permission.camera].request();
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
                title: Text("Capture Image", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final images = await _picker.pickImage(source: ImageSource.camera);
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
                title: Text("Capture Video", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final video = await _picker.pickVideo(source: ImageSource.camera);
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
                title: Text("Choose Image", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final images = await _picker.pickImage(source: ImageSource.gallery);
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
                title: Text("Choose Video", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final video = await _picker.pickVideo(source: ImageSource.gallery);
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
      setState(() {
        isLoading = true; // Show a loading indicator
      });

      Uint8List? compressedBytes;
      String fileName = image!.name;

      if (isImage) {
        compressedBytes = await MediaCompression.compressImage(File(image!.path));
      } else {
        final mediaInfo = await MediaCompression.compressVideo(File(image!.path));
        if (mediaInfo != null && mediaInfo.file != null) {
          compressedBytes = await mediaInfo.file!.readAsBytes();
          fileName = mediaInfo.path!.split('/').last;
        }
      }

      if (compressedBytes != null) {
        _sendMessage(type: isImage ? ChatMessageType.Image : ChatMessageType.Video, fileBytes: compressedBytes, fileName: fileName);
      }

      setState(() {
        isLoading = false; // Hide loading indicator
        image = null; // Reset the image
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();
    MyPrint.printOnConsole("Chat Message Screen build called for message check avatar: ${widget.chatInfo.avatar}");

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: themeData.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, color: themeData.colorScheme.onSurface, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          title: GestureDetector(
            onTap: _showGroupDetails,
            child: Row(
              children: [
                Stack(
                  children: [
                    CommonCachedNetworkImage(imageUrl: widget.chatInfo.avatar, height: 40, width: 40, fit: BoxFit.cover, borderRadius: 20),
                    if (widget.chatInfo.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Styles.grey400,
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
                        widget.chatInfo.type == ChatRoomType.Group ? widget.chatInfo.groupName ?? '' : widget.chatInfo.nickname,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: themeData.colorScheme.onSurface),
                      ),
                      if (widget.chatInfo.type == ChatRoomType.Group)
                        Text('${widget.chatInfo.receivers?.length ?? 0} members', style: TextStyle(fontSize: 10, color: Colors.grey[600]))
                      else
                        Text(widget.chatInfo.username, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (widget.chatInfo.type != ChatRoomType.Group)
              IconButton(
                icon: Icon(Icons.call_outlined, color: themeData.colorScheme.onSurface),
                onPressed: () async {
                  // Get the CallController from the provider
                  final callProvider = context.read<CallProvider>();
                  final callController = callProvider.callController;

                  // Start the call with the current chat user's ID
                  await callController.startCall(widget.chatInfo.id, receiverName: widget.chatInfo.nickname, receiverAvatar: widget.chatInfo.avatar);

                  // Navigate to the new call screen
                  if (mounted) {
                    NavigationController.navigateToVoiceCallScreen(
                      navigationOperationParameters: NavigationOperationParameters(context: context, navigationType: NavigationType.pushNamed),
                      arguments: VoiceCallScreenNavigationArguments(user: widget.chatInfo),
                    );
                  }
                },
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: themeData.colorScheme.onSurface),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearChatDialog();
                } else if (value == 'delete') {
                  _showDeleteChatDialog();
                }
              },
              itemBuilder: (context) => const [PopupMenuItem(value: 'clear', child: Text('Clear Chat')), PopupMenuItem(value: 'delete', child: Text('Delete Chat'))],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final msgList = chatProvider.getMessagesFor(widget.chatInfo.id);
                  final isLoadingMore = _isLoadingMore;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      return MessageBubble(message: message, chatController: _chatController, chatId: widget.chatInfo.id, chatRoomType: widget.chatInfo.type, avatar: profilePicPath);
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
                      final baseWidth = MediaQuery.of(context).size.width - 32 - 44 - 44 - 16;
                      final compactWidth = baseWidth * 1;
                      final expandedWidth = baseWidth;

                      final currentWidth = compactWidth + (_widthAnimation.value * (expandedWidth - compactWidth));

                      return SizedBox(
                        height: 50,
                        width: currentWidth,
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(color: themeData.colorScheme.primary, width: 1),
                            ),
                            suffixIcon: Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(CupertinoIcons.flame_fill, color: themeData.primaryColor),
                                  onPressed: () async {
                                    final selectedTime = await showTimeSelectionDialog(context);
                                    if (selectedTime != null) {
                                      print("User selected: $selectedTimeForDestruct");
                                      setState(() {}); // Add setState to rebuild the widget
                                    }
                                  },
                                ),
                                selectedTimeForDestruct == 0
                                    ? SizedBox()
                                    : InkWell(
                                  onTap: () async {
                                    final selectedTime = await showTimeSelectionDialog(context);
                                    if (selectedTime != null) {
                                      print("User selected: $selectedTimeForDestruct");
                                      setState(() {}); // Add setState to rebuild the widget
                                    }
                                  },
                                  child: Container(
                                    height: 18,
                                    // Increased size for better readability
                                    width: 18,
                                    // Increased size for better readability
                                    margin: EdgeInsets.only(top: 5),
                                    decoration: BoxDecoration(color: Styles.grey500, shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        _formatDestructTime(selectedTimeForDestruct),
                                        // Use the new formatting function
                                        style: TextStyle(
                                          fontSize: 8, // Adjusted font size
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onSubmitted: (_) {
                            _hasText ? _sendMessage(type: ChatMessageType.Text, textMessage: _messageController.text.trim()) : null;
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
                    decoration: BoxDecoration(color: Styles.grey400, borderRadius: BorderRadius.circular(22)),
                    child: AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return IconButton(
                          icon: AnimatedSwitcher(
                            duration: Duration(milliseconds: 200),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(opacity: animation, child: child),
                              );
                            },
                            child: _hasText ? Icon(Icons.send, key: ValueKey('send'), color: Colors.white, size: 20) : Icon(Icons.mic, key: ValueKey('mic'), color: Colors.white, size: 20),
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
      ),
    );
  }

  int selectedTimeForDestruct = 1440; // Default to 24 hours

  String _formatDestructTime(int minutes) {
    if (minutes == 0) {
      return "";
    } else if (minutes < 60) {
      return "${minutes}m";
    } else if (minutes < 1440) {
      return "${(minutes / 60).round()}h";
    } else {
      return "${(minutes / 1440).round()}d";
    }
  }

  Future<int?> showTimeSelectionDialog(BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Select time for destroy message',
            style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
            [
              {'label': 'None', 'value': 0},
              {'label': '1 minute', 'value': 1},
              {'label': '5 minutes', 'value': 5},
              {'label': '10 minutes', 'value': 10},
              {'label': '15 minutes', 'value': 15},
              {'label': '24 hours', 'value': 1440},
              {'label': '7 days', 'value': 10080},
            ].map((time) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: InkWell(
                  onTap: () {
                    selectedTimeForDestruct = time['value'] as int;
                    Navigator.pop(context, selectedTimeForDestruct);
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
                          color: selectedTimeForDestruct == (time['value'] as int) ? Colors.black : Colors.transparent,
                        ),
                      ),
                      SizedBox(width: 7),
                      Text('${time['label']}', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
