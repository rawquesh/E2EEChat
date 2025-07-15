import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';

import '../screens/chat_list_screen.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;

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
                  child: Text(
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
                    if (widget.message.isMe) ...[
                      SizedBox(width: 4),
                      Icon(
                        widget.message.status == MessageStatus.sent
                            ? Icons.check
                            : widget.message.status == MessageStatus.delivered
                            ? Icons.done_all
                            : Icons.done_all,
                        size: 12,
                        color: widget.message.status == MessageStatus.read
                            ? Color(0xFFE6A532)
                            : Colors.grey[500],
                      ),
                    ],
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
}