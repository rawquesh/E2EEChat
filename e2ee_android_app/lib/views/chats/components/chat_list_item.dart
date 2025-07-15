import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';

import '../screens/chat_list_screen.dart';

class ChatListItem extends StatefulWidget {
  final ChatUser user;
  final VoidCallback onTap;

  const ChatListItem({
    Key? key,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> with MySafeState{
  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: widget.onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeData.primaryColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  widget.user.avatar,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 0.8),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          widget.user.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          widget.user.lastMessage,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              widget.user.lastMessageTime,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 4),
            if (widget.user.unreadCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFE6A532),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.user.unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}