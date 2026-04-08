import '../../core/parsing_helper.dart';

enum ChatRoomType { Single, Group }

class ChatUserModel {
  String id;
  String nickname;
  String username;
  String avatar;
  String lastMessage;
  String lastMessageTime;
  bool isOnline;
  int unreadCount;
  final ChatRoomType type;
  final String? groupName;
  final List<String>? receivers;

  ChatUserModel({
    this.id = '',
    this.nickname = '',
    this.username = '',
    this.avatar = '',
    this.lastMessage = '',
    this.lastMessageTime = '',
    this.isOnline = false,
    this.unreadCount = 0,
    this.type = ChatRoomType.Single,
    this.groupName,
    this.receivers,
  });

  factory ChatUserModel.fromMap(Map<String, dynamic> map) {
    final nickname = ParsingHelper.parseStringMethod(map['name'] ?? map['username']);
    final avatarUrl = ParsingHelper.parseStringMethod(map['avatar']);

    return ChatUserModel(
      id: ParsingHelper.parseStringMethod(map['id']),
      nickname: nickname,
      username: ParsingHelper.parseStringMethod(map['username']),
      avatar: (avatarUrl.isNotEmpty)
          ? avatarUrl
          : (nickname.isNotEmpty ? nickname[0].toUpperCase() : ''),
      lastMessage: ParsingHelper.parseStringMethod(map['last_message']),
      lastMessageTime:
      ParsingHelper.parseStringMethod(map['last_message_time']),
      isOnline: ParsingHelper.parseBoolMethod(map['is_online']),
      unreadCount: ParsingHelper.parseIntMethod(map['unread_count']),
      type: (ParsingHelper.parseStringMethod(map['type']).toLowerCase()) ==
          "group"
          ? ChatRoomType.Group
          : ChatRoomType.Single,
      groupName: ParsingHelper.parseStringMethod(map['group_name']),
      receivers:
      map['receivers'] == null ? [] : List<String>.from(map['receivers']),
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
      'type': type.name.toLowerCase(),
      'group_name': groupName,
      'receivers': receivers,
    };
  }
}
