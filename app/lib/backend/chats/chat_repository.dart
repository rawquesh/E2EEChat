import 'dart:convert';

import 'package:e2ee_android_app/helpers/encryption_helper.dart';
import 'package:e2ee_android_app/models/chats/chat_message_model.dart';
import 'package:e2ee_android_app/models/chats/chat_user_model.dart';
import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_client_socket/pusher_client_socket.dart';

import '../authentication/auth_utils.dart';
import '../common/api_endpoints.dart';

class ChatRepository {
  PusherClient? _pusher;
  Channel? _channel;

  // initPusher remains the same
  void initPusher({required String userId, required String token, required Function(dynamic data) onMessageReceived}) {
    final options = PusherOptions(
      key: ApiEndpoints.pusherKey,
      cluster: ApiEndpoints.pusherCluster,
      host: ApiEndpoints.pusherHost,
      wsPort: ApiEndpoints.pusherWsPort,
      wssPort: ApiEndpoints.pusherWssPort,
      encrypted: ApiEndpoints.pusherEncrypted,
      authOptions: PusherAuthOptions(ApiEndpoints.pusherBroadcastingAuthUrl, headers: {'Authorization': 'Bearer $token'}),
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
      printLongText("[PUSHER REPO] Received MessageSent event: $data");
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

    // The inner message payload now contains the text, file info, etc.
    var innerMessagePayload = message.toMap();
    innerMessagePayload['destructTimer'] = timeInSecond;

    // Determine recipients for encryption
    List<String> recipientIds = [];
    if (messageContext['type'] == 'group') {
      recipientIds = List<String>.from(messageContext['receivers'] ?? []);
    } else {
      recipientIds = [messageContext['receiver_id']];
    }

    MyPrint.printOnConsole("XXEN Recipients for encryption: $recipientIds");
    MyPrint.printOnConsole("XXEN data: $innerMessagePayload");

    // Encrypt the payload
    final encryptionService = EncryptionHelper();
    var encryptedPayload = await encryptionService.encryptPayload(payload: innerMessagePayload, recipientIds: recipientIds, token: token);

    if (encryptedPayload == null) {
      MyPrint.printOnConsole("XXEN Encryption failed. Cannot send message.");
      return false;
    }

    // Construct final body according to the new structure
    final body = jsonEncode({
      ...messageContext,
      "message": {...innerMessagePayload, ...encryptedPayload},
    });

    printLongText('[SEND DEBUG] Final Request Body: $body');

    // Send the request
    final url = Uri.parse(ApiEndpoints.urlSendMessage);
    MyPrint.printOnConsole('[SEND DEBUG] POST $url');

    try {
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: body);
      MyPrint.printOnConsole('[SEND DEBUG] Status: ${response.statusCode}');
      if (response.statusCode == 401) {
        await AuthUtils.handleUnauthorized();
      }
      return response.statusCode == 200;
    } catch (e) {
      MyPrint.printOnConsole('[SEND DEBUG] Error sending message: $e');
      return false;
    }
  }

  void printLongText(String text) {
    const int chunkSize = 800;
    for (var i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      MyPrint.printOnConsole(text.substring(i, end));
    }
  }

  // fetchChatUser remains the same
  Future<ChatUserModel?> fetchChatUser({String? username, String? userId, required String token}) async {
    final url = Uri.parse(ApiEndpoints.urlGetOpponent);
    final Map<String, dynamic> bodyMap = {};
    if (username != null && username.isNotEmpty) bodyMap['username'] = username;
    if (userId != null && userId.isNotEmpty) bodyMap['userid'] = userId;
    if (bodyMap.isEmpty) return null;
    final body = jsonEncode(bodyMap);
    final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json", "Authorization": "Bearer $token"}, body: body);

    if (response.statusCode == 401) {
      await AuthUtils.handleUnauthorized();
    }

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body)['data'];
      return ChatUserModel.fromMap(data);
    } else {
      return null;
    }
  }

  Future<String?> fetchPublicKey({required String? userId, required String token}) async {
    // 1. Guard against a null userId to prevent the error
    if (userId == null || userId.isEmpty) {
      MyPrint.printOnConsole("XXEN Error: userId is null or empty.");
      return null;
    }

    final url = Uri.parse(ApiEndpoints.urlUserKeys(userId));

    try {
      final response = await http.get(url, headers: {"Accept": "application/json", "Authorization": "Bearer $token"});

      MyPrint.printOnConsole("Response status for user $userId: ${response.statusCode}");

      if (response.statusCode == 401) {
        await AuthUtils.handleUnauthorized();
      }

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

  /// Fetches any messages stored on the server that arrived while the app was offline.
  /// The server returns the encrypted payload — decryption is handled by the caller.
  /// Returns a list of raw message maps from the server.
  Future<List<Map<String, dynamic>>> fetchPendingMessages({required String token}) async {
    final url = Uri.parse(ApiEndpoints.urlPendingMessages);

    try {
      final response = await http.get(url, headers: {"Accept": "application/json", "Authorization": "Bearer $token"});

      MyPrint.printOnConsole('[PENDING MESSAGES] Status: ${response.statusCode}');

      if (response.statusCode == 401) {
        await AuthUtils.handleUnauthorized();
        return [];
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic>? messages = body['messages'];
        if (messages != null) {
          MyPrint.printOnConsole('[PENDING MESSAGES] Received ${messages.length} pending messages');
          return messages.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      MyPrint.printOnConsole('[PENDING MESSAGES] Error fetching pending messages: $e');
      return [];
    }
  }
}

// curl --location '${ApiEndpoints.apiBaseUrl}${ApiEndpoints.userKeys}/<USER_ID>/keys' \

// --header 'Accept: application/json' \

// --header 'Content-Type: application/json' \

// --header 'Authorization: Bearer <TOKEN>' \

// --data ''
