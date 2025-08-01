import 'dart:convert';
import 'package:e2ee_android_app/utils/encryption_service.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:http/http.dart' as http;

import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:pusher_client_socket/pusher_client_socket.dart';

class ChatRepository {
  final String baseUrl = 'https://172.86.92.130.sslip.io/api';
  PusherClient? _pusher;
  Channel? _channel;

  // initPusher remains the same
  void initPusher({required String userId, required String token, required Function(dynamic data) onMessageReceived}) {
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
    required Map<String, dynamic> messageContext, // Contains sender, receiver/group info
    required ChatMessageData message,
    required int destructTimer,
  }) async {
    int timeInSecond = destructTimer * 60;

    var innerMessagePayload = message.toMap();
    innerMessagePayload.addAll({
      "username": messageContext['username'],
      "nickname": messageContext['nickname'],
      "destructTimer": timeInSecond,
    });


// TODO for this logic to work, make the necessary changes.
    // Determine recipients for encryption
    List<String> recipientIds = [];
    if (messageContext['type'] == 'group') {
      recipientIds = List<String>.from(messageContext['recievers'] ?? []);
    } else {
      recipientIds = [messageContext['receiver_id']];
    }

    // Encrypt the payload
    final encryptionService = EncryptionService();
    var encryptedPayload = await encryptionService.encryptPayload(
      payload: innerMessagePayload,
      recipientIds: recipientIds,
      token: token,
    );

    if (encryptedPayload == null) {
      MyPrint.printOnConsole("XXEN Encryption failed. Cannot send message.");
      return false;
    }

    // Construct final body
    final body = jsonEncode({
      ...messageContext, // Spread all context fields
      "message": encryptedPayload,
    });

    // Send the request
    final url = Uri.parse('$baseUrl/send-message');
    MyPrint.printOnConsole('[SEND DEBUG] POST $url');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
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
  Future<ChatUserModel?> fetchChatUser({String? username, String? userId, required String token}) async {
    final url = Uri.parse('$baseUrl/chat/getopponent');
    final Map<String, dynamic> bodyMap = {};
    if (username != null && username.isNotEmpty) bodyMap['username'] = username;
    if (userId != null && userId.isNotEmpty) bodyMap['userid'] = userId;
    if (bodyMap.isEmpty) return null;
    final body = jsonEncode(bodyMap);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Accept": "application/json", "Authorization": "Bearer $token"},
      body: body,
    );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body)['data'];
      return ChatUserModel.fromMap(data);
    } else {
      return null;
    }
  }

  Future<List<ChatUserModel>> fetchChatUsers({required String query, required String token}) async {
    final url = Uri.parse('$baseUrl/chat/get-opponents');
    final body = jsonEncode({'query': query});
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json", "Accept": "application/json", "Authorization": "Bearer $token"},
      body: body,
    );

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body)['data'];
      if (data is List) {
        return data.map((user) => ChatUserModel.fromMap(user)).toList();
      }
    }
    return [];
  }

  Future<String?> fetchPublicKey({required String? userId, required String token}) async {
    // 1. Guard against a null userId to prevent the error
    if (userId == null || userId.isEmpty) {
      MyPrint.printOnConsole("XXEN Error: userId is null or empty.");
      return null;
    }

    final url = Uri.parse('$baseUrl/users/$userId/keys');

    try {
      final response = await http.get(url, headers: {"Accept": "application/json", "Authorization": "Bearer $token"});

      MyPrint.printOnConsole("Response status for user $userId: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final Map<String, dynamic>? data = body['data'];
        final String? publicKey = data?['publicKey'];

        if (publicKey != null && publicKey.isNotEmpty) {
          MyPrint.printOnConsole('Successfully parsed publicKey!');
          return publicKey;
        } else {
          MyPrint.printOnConsole('Error: publicKey key not found or is empty in the response data.');
          return null;
        }
      } else {
        MyPrint.printOnConsole("Failed to fetch key. Server responded with ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("An exception occurred during the network request: $e");
      return null;
    }
  }
}


// curl --location 'https://172.86.92.130.sslip.io/api/users/<USER_ID>/keys' \
 
// --header 'Accept: application/json' \
 
// --header 'Content-Type: application/json' \
 
// --header 'Authorization: Bearer <TOKEN>' \

// --data ''