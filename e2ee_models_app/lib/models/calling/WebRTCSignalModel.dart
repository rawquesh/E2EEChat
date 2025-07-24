class WebRTCSignalModel {
  String type;
  Map<String, dynamic>? data;
  String senderId;
  String receiverId;

  WebRTCSignalModel({
    required this.type,
    this.data,
    this.senderId = '',
    this.receiverId = '',
  });

  factory WebRTCSignalModel.fromMap(Map<String, dynamic> map) {
    return WebRTCSignalModel(
      type: map['type']?.toString() ?? '',
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      senderId: map['sender_id']?.toString() ?? '',
      receiverId: map['receiver_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'data': data,
      'sender_id': senderId,
      'receiver_id': receiverId,
    };
  }
}
