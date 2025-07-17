import 'package:e2ee_models_app/utils/my_safe_state.dart';
import 'package:flutter/material.dart';

import '../../../backend/chats/chat_repository.dart';
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

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] ?? '',
      isOnline: json['is_online'] ?? false,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
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

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatUser>> _chatFuture;

  @override
  void initState() {
    super.initState();
    // For "u111"
    final repo = ChatRepository(
      username: "user2",
      token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovLzE3Mi44Ni45Mi4xMzAuc3NsaXAuaW8vYXBpL2F1dGgvcmVnaXN0ZXIiLCJpYXQiOjE3NTI3ODEwNDksImV4cCI6MTc1ODc4MTA0OSwibmJmIjoxNzUyNzgxMDQ5LCJqdGkiOiJ5SEVJdzRQN1FJdnVYMHRHIiwic3ViIjoiZGVlMmZiOGItYjVmYS00MmI3LTllYmQtY2QzNDEyZTNkZmY4IiwicHJ2IjoiMjNiZDVjODk0OWY2MDBhZGIzOWU3MDFjNDAwODcyZGI3YTU5NzZmNyIsInVzZXJuYW1lIjoidXNlcjEiLCJyb2xlIjpbXSwic2Vzc2lvbl90b2tlbiI6ImZmYWFjOWVkLWYzZDYtNGM1Ni1hY2NmLWJmYzhmZTU5N2QyOCJ9.1GDeNR4CnsOQaS3m6zKM_ruwGMW-c4e6Aj_QELvGdyc",
    );
    // For "u1112", swap these two lines above with the token you provided.
    _chatFuture = repo.fetchChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),
          Text(
            'DarkCrypt Chat',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<ChatUser>>(
              future: _chatFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Failed to load chats'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No chats found'));
                }
                final users = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}