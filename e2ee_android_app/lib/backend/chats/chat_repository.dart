import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';

class ChatRepository {
  final String baseUrl = 'https://172.86.92.130.sslip.io/api';
  PusherClient? _pusher;
  Channel? _channel;

  // initPusher remains the same
  void initPusher({
    required String userId,
    required String token,
    required Function(dynamic data) onMessageReceived,
  }) {
    final options = PusherOptions(
      key: 'sip6lkxyrl3d0um6vbv9',
      cluster: 'mt1',
      host: '172.86.92.130.sslip.io',
      wsPort: 8080,
      wssPort: 443,
      encrypted: false,
      authOptions: PusherAuthOptions(
        'https://172.86.92.130.sslip.io/broadcasting/auth',
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    _pusher = PusherClient(options: options);

    _pusher!.onConnectionEstablished((_) {
      MyPrint.printOnConsole('[PUSHER REPO] Connection established - socket-id: ${_pusher!.socketId}');
    });

    _pusher!.onConnectionError((error) => MyPrint.printOnConsole('[PUSHER REPO] Connection error: $error'));
    _pusher!.onError((error) => MyPrint.printOnConsole('[PUSHER REPO] Error: $error'));

    _pusher!.connect();

    final channelName = 'private-chat.$userId';
    _channel = _pusher!.channel(channelName);

    _channel!.bind('MessageSent', (data) {
      MyPrint.printOnConsole('[PUSHER REPO] Received MessageSent event: $data');
      if (data != null) {
        onMessageReceived(data);
      }
    });
  }

  // disposePusher remains the same
  void disposePusher() {
    try {
      _channel?.unbind('MessageSent');
      _pusher?.disconnect();
      MyPrint.printOnConsole('[PUSHER REPO] Disposed Pusher connection.');
    } catch (e) {
      MyPrint.printOnConsole('[PUSHER REPO] Error disposing pusher: $e');
    }
  }

  Future<bool> sendMessage({
    required String token,
    required String senderId,
    required String senderName, // ✨ 1. Add senderName parameter
    required String receiverId,
    required String message,
    required int destructTimer,
  }) async {
    int timeInSecond = destructTimer * 60;
    final url = Uri.parse('$baseUrl/send-message');
    final body = jsonEncode({
      "sender_id": senderId,
      "receiver_id": receiverId,
      //"message": message,
      "message": {"message":message, "destructTimer": timeInSecond, "senderName": senderName},
    });
    MyPrint.printOnConsole('[SEND DEBUG] POST $url with body: $body');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: body,
      );
      MyPrint.printOnConsole('[SEND DEBUG] Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      MyPrint.printOnConsole('[SEND DEBUG] Error sending message: $e');
      return false;
    }
  }

  // fetchChatUser remains the same
  Future<ChatUserModel?> fetchChatUser({
    String? username,
    String? userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/chat/getopponent');
    final Map<String, dynamic> bodyMap = {};
    if (username != null && username.isNotEmpty) bodyMap['username'] = username;
    if (userId != null && userId.isNotEmpty) bodyMap['userid'] = userId;
    if (bodyMap.isEmpty) return null;
    final body = jsonEncode(bodyMap);
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body)['data'];
      return ChatUserModel.fromMap(data);
    } else {
      return null;
    }
  }
}