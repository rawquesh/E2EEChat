class ChatUserModel {
  String id;
  String nickname;
  String username;
  String avatar;
  String lastMessage;
  String lastMessageTime;
  bool isOnline;
  int unreadCount;

  ChatUserModel({
    this.id = '',
    this.nickname = '',
    this.username = '',
    this.avatar = '',
    this.lastMessage = '',
    this.lastMessageTime = '',
    this.isOnline = false,
    this.unreadCount = 0,
  });

  factory ChatUserModel.fromMap(Map<String, dynamic> map) {
    return ChatUserModel(
      id: map['id']?.toString() ?? '',
      nickname: map['name'] ?? map['username'] ?? '',
      username: map['username'] ?? '',
      avatar: (map['username'] ?? map['name'] ?? '').toString().isNotEmpty ? (map['username'] ?? map['name'])[0].toUpperCase() : '',
      lastMessage: map['last_message'] ?? '',
      lastMessageTime: map['last_message_time'] ?? '',
      isOnline: map['is_online'] ?? false,
      unreadCount: map['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': nickname,
      'username': username,
      'avatar': avatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'is_online': isOnline,
      'unread_count': unreadCount,
    };
  }
}
