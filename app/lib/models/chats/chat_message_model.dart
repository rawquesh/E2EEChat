import 'dart:convert';

import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:e2ee_android_app/utils/my_utils.dart';
import 'package:e2ee_android_app/helpers/parsing_helper.dart';

class ChatMessageData {
  String type;
  String base64String;
  String text;
  String fileName;
  String? senderNickname;
  String nickname;
  String username;
  String? avatar;
  int destructTimer;
  String? iv;
  Map<String, String>? keys;
  Map<String, dynamic>? rawMap;

  ChatMessageData({
    this.type = '',
    this.base64String = '',
    this.text = '',
    this.fileName = '',
    this.senderNickname,
    this.nickname = '',
    this.username = '',
    this.avatar,
    this.destructTimer = 0,
    this.iv,
    this.keys,
    this.rawMap,
  });

  factory ChatMessageData.fromMap(Map<String, dynamic> map) {
    return ChatMessageData(
      type: ParsingHelper.parseStringMethod(map['type']),
      base64String: ParsingHelper.parseStringMethod(map['base64String']),
      text: ParsingHelper.parseStringMethod(map['text']),
      fileName: ParsingHelper.parseStringMethod(map['fileName']),
      nickname: ParsingHelper.parseStringMethod(map['nickname']),
      senderNickname: ParsingHelper.parseStringMethod(map['sender_nickname']),
      username: ParsingHelper.parseStringMethod(map['username']),
      avatar: map['avatar'] != null ? ParsingHelper.parseStringMethod(map['avatar']) : null,
      destructTimer: ParsingHelper.parseIntMethod(map['destructTimer']),
      iv: ParsingHelper.parseStringMethod(map['iv']),
      keys: map['keys'] is Map ? Map<String, String>.from(map['keys']) : null,
      rawMap: map,
    );
  }

  Map<String, dynamic> toMap({bool toJson = true}) {
    final data = {
      'type': type,
      'base64String': base64String,
      'text': text,
      'fileName': fileName,
      'sender_nickname': senderNickname,
      'username': username,
      'destructTimer': destructTimer,
      'nickname': nickname,
      'avatar': avatar ?? '',
    };

    if (iv != null) data['iv'] = iv;
    if (keys != null) data['keys'] = keys;

    return data;
  }

  @override
  String toString() => MyUtils.encodeJson(toMap());
}

class ChatMessageModel {
  String id;
  String senderId;
  ChatMessageData message;
  DateTime timestamp;
  DateTime destructTimestamp;
  bool isMe;
  String status;

  ChatMessageModel({this.id = '', this.senderId = '', ChatMessageData? message, DateTime? timestamp, DateTime? destructTimestamp, this.isMe = false, this.status = ''})
    : message = message ?? ChatMessageData(),
      timestamp = timestamp ?? DateTime.now(),
      destructTimestamp = destructTimestamp ?? DateTime.now().add(const Duration(days: 365 * 100));

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, {required String currentUserId}) {
    ChatMessageData messageData;
    final dynamic messageValue = map['message'];

    if (messageValue is Map) {
      final messageMap = Map<String, dynamic>.from(messageValue);
      messageData = ChatMessageData.fromMap(messageMap);
    } else if (messageValue is String && messageValue.isNotEmpty) {
      try {
        final decodedMessage = json.decode(messageValue) as Map<String, dynamic>;
        messageData = ChatMessageData.fromMap(decodedMessage);
      } catch (e) {
        MyPrint.printOnConsole("Error decoding message JSON string: $e");
        messageData = ChatMessageData();
      }
    } else {
      messageData = ChatMessageData();
    }

    return ChatMessageModel(
      id: ParsingHelper.parseStringMethod(map['id']),
      senderId: ParsingHelper.parseStringMethod(map['sender_id']),
      message: messageData,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      destructTimestamp: DateTime.tryParse(map['destructTimestamp'] ?? '') ?? DateTime.now().add(const Duration(days: 365 * 100)),
      isMe: ParsingHelper.parseStringMethod(map['sender_id']) == currentUserId,
      status: ParsingHelper.parseStringMethod(map['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
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
