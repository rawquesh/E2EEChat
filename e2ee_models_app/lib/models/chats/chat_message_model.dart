import 'dart:convert';

import '../../utils/my_utils.dart';
import '../../utils/parsing_helper.dart';

// New class to hold the structured message data.
class ChatMessageData {
  String type;
  String base64String;
  String text;
  String fileName;

  ChatMessageData({
    this.type = '',
    this.base64String = '',
    this.text = '',
    this.fileName = '',
  });

  // Factory constructor to create a ChatMessageData instance from a map.
  factory ChatMessageData.fromMap(Map<String, dynamic> map) {
    return ChatMessageData(
      type: ParsingHelper.parseStringMethod(map['type']),
      base64String: ParsingHelper.parseStringMethod(map['base64String']),
      text: ParsingHelper.parseStringMethod(map['text']),
      fileName: ParsingHelper.parseStringMethod(map['fileName']),
    );
  }

  // Method to convert a ChatMessageData instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'base64String': base64String,
      'text': text,
      'fileName': fileName,
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}


class ChatMessageModel {
  String id;
  String senderId;
  // The 'message' field is now of type ChatMessageData.
  ChatMessageData message;
  DateTime timestamp;
  DateTime destructTimestamp;
  bool isMe;
  String status;

  ChatMessageModel({
    this.id = '',
    this.senderId = '',
    ChatMessageData? message,
    DateTime? timestamp,
    DateTime? destructTimestamp,
    this.isMe = false,
    this.status = '',
  })  : message = message ?? ChatMessageData(), // Default to an empty ChatMessageData object.
        timestamp = timestamp ?? DateTime.now(),
        destructTimestamp = destructTimestamp ?? DateTime.now().add(Duration(days: 365 * 100));

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, {required String currentUserId}) {
    // Ensure 'message' from the map is treated as a Map, even if it's null.
    final messageData = map['message'] is Map<String, dynamic>
        ? ChatMessageData.fromMap(map['message'])
        : ChatMessageData(); // Provide a default if it's not a map.

    return ChatMessageModel(
      id: ParsingHelper.parseStringMethod(map['id']),
      senderId: ParsingHelper.parseStringMethod(map['sender_id']),
      // Use the factory constructor of ChatMessageData to parse the message map.
      message: messageData,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      destructTimestamp: DateTime.tryParse(map['destructTimestamp'] ?? '') ?? DateTime.now().add(Duration(days: 365 * 100)),
      isMe: ParsingHelper.parseStringMethod(map['sender_id']) == currentUserId,
      status: ParsingHelper.parseStringMethod(map['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      // Call the toMap() method on the message object to serialize it.
      'message': message.toMap(),
      'timestamp': timestamp.toIso8601String(),
      'destructTimestamp': destructTimestamp.toIso8601String(),
      'is_me': isMe,
      'status': status,
    };
  }

  @override
  String toString() {
    return MyUtils.encodeJson(toMap());
  }
}
