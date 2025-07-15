import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';

import '../components/chat_list_item.dart';
import 'chat_message_screen.dart';

class ChatUser {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String lastMessageTime;
  final bool isOnline;
  final int unreadCount;

  ChatUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isOnline,
    required this.unreadCount,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isMe;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.isMe,
    required this.status,
  });
}

enum MessageStatus { sent, delivered, read }

// Dummy Data
class ChatData {
  static List<ChatUser> users = [
    ChatUser(
      id: '1',
      name: 'Sarah Johnson',
      avatar: 'S',
      lastMessage: 'Hey! How are you doing?',
      lastMessageTime: '2m ago',
      isOnline: true,
      unreadCount: 2,
    ),
    ChatUser(
      id: '2',
      name: 'Mike Chen',
      avatar: 'M',
      lastMessage: 'The meeting is scheduled for 3 PM',
      lastMessageTime: '15m ago',
      isOnline: false,
      unreadCount: 0,
    ),
    ChatUser(
      id: '3',
      name: 'Emily Davis',
      avatar: 'E',
      lastMessage: 'Thanks for the help!',
      lastMessageTime: '1h ago',
      isOnline: true,
      unreadCount: 1,
    ),
    ChatUser(
      id: '4',
      name: 'Alex Wilson',
      avatar: 'A',
      lastMessage: 'Can you review the document?',
      lastMessageTime: '3h ago',
      isOnline: false,
      unreadCount: 0,
    ),
    ChatUser(
      id: '5',
      name: 'Lisa Zhang',
      avatar: 'L',
      lastMessage: 'Perfect! See you tomorrow.',
      lastMessageTime: '5h ago',
      isOnline: true,
      unreadCount: 0,
    ),
  ];

  static List<ChatMessage> getMessagesForUser(String userId) {
    return [
      ChatMessage(
        id: '1',
        senderId: userId,
        message: 'Hey! How are you doing?',
        timestamp: DateTime.now().subtract(Duration(minutes: 2)),
        isMe: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '2',
        senderId: 'me',
        message: 'I\'m doing great! Thanks for asking. How about you?',
        timestamp: DateTime.now().subtract(Duration(minutes: 1)),
        isMe: true,
        status: MessageStatus.delivered,
      ),
      ChatMessage(
        id: '3',
        senderId: userId,
        message: 'I\'m good too! Just finished a big project at work.',
        timestamp: DateTime.now().subtract(Duration(seconds: 30)),
        isMe: false,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '4',
        senderId: 'me',
        message: 'That\'s awesome! What kind of project was it?',
        timestamp: DateTime.now().subtract(Duration(seconds: 10)),
        isMe: true,
        status: MessageStatus.sent,
      ),
    ];
  }
}

// Main Chat List Screen
class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with MySafeState {
  @override
  Widget build(BuildContext context) {
    super.pageBuild();

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),
          Text(
            'DarkCrypt Chat',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.primary,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: ChatData.users.length,
              itemBuilder: (context, index) {
                final user = ChatData.users[index];
                return ChatListItem(
                  user: user,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatMessageScreen(user: user),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
