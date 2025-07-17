import 'dart:convert';

import '../../views/chats/screens/chat_list_screen.dart';
import 'package:http/http.dart' as http;

class ChatRepository {
  // Choose username and token to test
  final String username;
  final String token;

  ChatRepository({required this.username, required this.token});

  Future<List<ChatUser>> fetchChatRooms() async {
    final url = Uri.parse('https://172.86.92.130.sslip.io/api/chat/getopponent');
    final body = jsonEncode({"username": username});
    print('Making POST request to $url with body: $body');

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body)['data'];
      // Build a dummy ChatUser from the minimal data
      final chatUser = ChatUser(
        id: data['id'] ?? "",
        name: data['username'] ?? "",
        avatar: data['username']?.substring(0, 1).toUpperCase() ?? "U",
        lastMessage: 'No messages yet',
        lastMessageTime: '',
        isOnline: false,
        unreadCount: 0,
      );
      return [chatUser]; // Return as a list of one item
    } else {
      throw Exception('Failed to load chats');
    }
  }
}