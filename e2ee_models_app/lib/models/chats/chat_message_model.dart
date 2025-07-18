import '../../utils/parsing_helper.dart';

class ChatMessageModel {
  String id;
  String senderId;
  String message;
  DateTime timestamp;
  bool isMe;
  String status;

  ChatMessageModel({
    this.id = '',
    this.senderId = '',
    this.message = '',
    DateTime? timestamp,
    this.isMe = false,
    this.status = '',
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, {required String currentUserId}) {
    return ChatMessageModel(
      id: ParsingHelper.parseStringMethod(map['id']),
      senderId: ParsingHelper.parseStringMethod(map['sender_id']),
      message: ParsingHelper.parseStringMethod(map['message']),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isMe: ParsingHelper.parseStringMethod(map['sender_id']) == currentUserId,
      status: ParsingHelper.parseStringMethod(map['status']),
    );
  }
}
