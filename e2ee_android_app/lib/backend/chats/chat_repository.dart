import 'dart:convert';

import 'package:e2ee_models_app/models/chats/chat_user_model.dart';

import '../../views/chats/screens/chat_list_screen.dart';
import 'package:http/http.dart' as http;

class ChatRepository {
  final String baseUrl = 'https://172.86.92.130.sslip.io/api';

  Future<ChatUserModel?> fetchChatUser({
    required String username,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/chat/getopponent');
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
      return ChatUserModel.fromMap(data);
    } else {
      return null;
    }
  }

  Future<bool> sendMessage({
    required String token,
    required String chatId,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/chat/send');
    final body = jsonEncode({"chat_id": chatId, "message": message});
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );
    return response.statusCode == 200;
  }
}