class ChatUserModel {
  String id;
  String nickname;
  String username;
  String avatar;
  String lastMessage;
  String lastMessageTime;
  bool isOnline;
  int unreadCount;
  bool isGroup; // New field to identify a group

  ChatUserModel({
    this.id = '',
    this.nickname = '',
    this.username = '',
    this.avatar = '',
    this.lastMessage = '',
    this.lastMessageTime = '',
    this.isOnline = false,
    this.unreadCount = 0,
    this.isGroup = false, // Default to false
  });

  factory ChatUserModel.fromMap(Map<String, dynamic> map) {
    bool isGroup = map['is_group'] ?? false;
    String name = map['name'] ?? map['username'] ?? '';

    return ChatUserModel(
      id: map['id']?.toString() ?? '',
      nickname: name, // Will hold user's nickname or group's name
      username: map['username'] ?? '',
      avatar: name.isNotEmpty ? name[0].toUpperCase() : '',
      lastMessage: map['last_message'] ?? '',
      lastMessageTime: map['last_message_time'] ?? '',
      // A group is never "online"
      isOnline: isGroup ? false : (map['is_online'] ?? false),
      unreadCount: map['unread_count'] ?? 0,
      isGroup: isGroup,
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
      'is_group': isGroup, // Add to map for serialization
    };
  }
}