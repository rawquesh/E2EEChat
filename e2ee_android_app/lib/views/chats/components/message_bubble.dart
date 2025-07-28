import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:e2ee_models_app/configs/styles.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:e2ee_models_app/utils/my_utils.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../configs/constants.dart';

import '../../../backend/chats/chats_controller.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessageModel message;
  final ChatController chatController;
  final String chatId;

  const MessageBubble(
      {Key? key,
      required this.message,
      required this.chatController,
      required this.chatId})
      : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with MySafeState {
  Timer? _timer;
  Duration? _remainingTime;

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String? filePath;

  @override
  void initState() {
    super.initState();

    if (widget.message.destructTimestamp.isAfter(DateTime.now())) {
      _remainingTime = widget.message.destructTimestamp.difference(
        DateTime.now(),
      );
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _remainingTime = widget.message.destructTimestamp.difference(
              DateTime.now(),
            );
            if (_remainingTime!.isNegative) {
              _timer?.cancel();
            }
          });
        }
      });
    }

    if (widget.message.message.startsWith(imageTypeChat) ||
        widget.message.message.startsWith(audioTypeChat) ||
        widget.message.message.startsWith(videoTypeChat) ||
        widget.message.message.startsWith(docTypeChat)) {
      filePath = widget.message.message.split(",").last;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return DateTime.now().isBefore(widget.message.destructTimestamp)
        ? InkWell(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Message Options"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.delete),
                        title: Text("Delete"),
                        onTap: () async {
                          Navigator.pop(context);
                          await widget.chatController
                              .deleteMessage(widget.chatId, widget.message.id);
                        },
                      ),
                      if (filePath != null)
                        ListTile(
                          leading: Icon(Icons.save),
                          title: Text("Save To Vault"),
                          onTap: () async {
                            Navigator.pop(context);
                            if (filePath != null) {
                              await MyUtils.saveFileToVault(filePath!);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: widget.message.isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!widget.message.isMe) ...[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Styles.grey400,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: widget.message.isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: widget.message.isMe
                                ? Styles.grey400
                                : themeData.colorScheme.onPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(
                                widget.message.isMe ? 16 : 4,
                              ),
                              bottomRight: Radius.circular(
                                widget.message.isMe ? 4 : 16,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              widget.message.message.startsWith(imageTypeChat)
                                  ? filePath == null
                                      ? SizedBox()
                                      : InkWell(
                                          onTap: () {
                                            OpenFilex.open(filePath);
                                          },
                                          child: Image.file(
                                            File(filePath!),
                                            height: 120,
                                            width: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                  : widget.message.message
                                          .startsWith(audioTypeChat)
                                      ? filePath == null
                                          ? SizedBox()
                                          : InkWell(
                                              onTap: () async {
                                                if (isPlaying) {
                                                  await _audioPlayer.stop();
                                                  setState(
                                                      () => isPlaying = false);
                                                } else {
                                                  await _playAudioFromFile();
                                                }
                                              },
                                              child: Container(
                                                width: 120,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isPlaying
                                                          ? Icons.pause
                                                          : Icons
                                                              .play_arrow_rounded,
                                                      color: Colors.white,
                                                      size: 30,
                                                    ),
                                                    Text(
                                                      "Audio",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                      : widget.message.message
                                              .startsWith(videoTypeChat)
                                          ? filePath == null
                                              ? SizedBox()
                                              : InkWell(
                                                  onTap: () async {
                                                    OpenFilex.open(filePath);
                                                  },
                                                  child: Container(
                                                    width: 120,
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .play_arrow_rounded,
                                                          color: Colors.white,
                                                          size: 30,
                                                        ),
                                                        Text(
                                                          "Video",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                          : widget.message.message
                                                  .startsWith(docTypeChat)
                                              ? filePath == null
                                                  ? SizedBox()
                                                  : InkWell(
                                                      onTap: () async {
                                                        OpenFilex.open(
                                                            filePath);
                                                      },
                                                      child: Container(
                                                        width: 120,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .folder_rounded,
                                                              color:
                                                                  Colors.white,
                                                              size: 25,
                                                            ),
                                                            SizedBox(width: 2),
                                                            Text(
                                                              "Document",
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                              : Text(
                                                  widget.message.message,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: widget.message.isMe
                                                        ? Colors.white
                                                        : themeData.colorScheme
                                                            .onSurface,
                                                  ),
                                                ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_remainingTime != null &&
                                !_remainingTime!.isNegative &&
                                widget.message.destructTimestamp
                                        .difference(DateTime.now())
                                        .inDays <
                                    365)
                              Row(
                                children: [
                                  Icon(
                                    Icons.whatshot,
                                    color: Colors.red,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatRemainingTime(_remainingTime!),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                ],
                              ),
                            Text(
                              _formatTime(widget.message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.message.isMe) ...[
                    SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: themeData.colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        : SizedBox();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isLoading = false;

  Future<void> _playAudioFromFile() async {
    if (filePath == null) return;

    setState(() => isLoading = true);

    try {
      await _audioPlayer.play(DeviceFileSource(filePath!));
      setState(() => isPlaying = true);

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() => isPlaying = false);
      });
    } catch (e) {
      print("Audio playback error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
}
