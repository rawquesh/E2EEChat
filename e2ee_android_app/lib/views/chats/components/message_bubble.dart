import 'dart:convert';
import 'dart:io';

import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'dart:typed_data';
import '../../../configs/constants.dart';
import '../screens/chat_list_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessageModel message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with MySafeState {
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

  //base64 image part
  Uint8List? imageBytes;
  Uint8List? audioBytes;

  @override
  void initState() {
    super.initState();
    if (widget.message.message.startsWith(imageTypeChat)) {
      String base64String = widget.message.message.split(",").last;
      imageBytes = base64Decode(base64String);
    }

    if (widget.message.message.startsWith(audioTypeChat)) {
      //String base64String = widget.message.message.replaceFirst(audioTypeChat, "");
      String base64String = widget.message.message.split(",").last;
      audioBytes = base64Decode(base64String);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: widget.message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.message.isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(0xFFE6A532),
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
              crossAxisAlignment: widget.message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.message.isMe ? Color(0xFFE6A532) : themeData.colorScheme.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(widget.message.isMe ? 16 : 4),
                      bottomRight: Radius.circular(widget.message.isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: widget.message.message.startsWith(imageTypeChat) ? imageBytes == null ? SizedBox():Image.memory(imageBytes!,height: 120,width: 120,fit: BoxFit.cover):

                  widget.message.message.startsWith(audioTypeChat) ? audioBytes == null ? SizedBox(): InkWell(
                    onTap: () async {
                      if (isPlaying) {
                        await _audioPlayer.stop();
                        setState(() => isPlaying = false);
                      } else {
                        await _playAudioFromBase64();
                      }
                    },
                    child: Container(width: 120,
                    child: Row(
                      children: [
                        Icon(isPlaying ? Icons.pause : Icons.play_arrow_rounded,color: Colors.white,size: 30,),
                        Text("Audio File",style: TextStyle(color: Colors.white,fontSize: 15),),
                      ],
                    ),
                    ),
                  ):

                  Text(
                    widget.message.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.message.isMe ? Colors.white : themeData.colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
    );
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isLoading = false;

  Future<void> _playAudioFromBase64() async {
    if (!widget.message.message.startsWith(audioTypeChat)) return;

    setState(() => isLoading = true);

    try {
      // Decode base64
      String base64String = widget.message.message.replaceFirst(audioTypeChat, "");
      Uint8List audioBytes = base64Decode(base64String);

      // Write to temp file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = File(filePath);
      await file.writeAsBytes(audioBytes);

      // Play from file
      await _audioPlayer.play(DeviceFileSource(filePath));
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