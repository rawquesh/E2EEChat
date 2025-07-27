import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/hive_manager.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:hive/hive.dart';

class ChatUsersRepository {
  static const String _chatUsersBoxName = 'chat_users';
  Box? _chatUsersBox;

  Future<Box?> _openBox() async {
    try {
      if (_chatUsersBox?.isOpen == true) {
        return _chatUsersBox;
      }
      _chatUsersBox = await HiveManager().openBox(boxName: _chatUsersBoxName);
      return _chatUsersBox;
    } catch (e) {
      MyPrint.printOnConsole('Error opening chat users box: $e');
      return null;
    }
  }

  // Save a single chat user
  Future<bool> saveChatUser(ChatUserModel user) async {
    try {
      final box = await _openBox();
      if (box == null) return false;

      await box.put(user.id, user.toMap());
      MyPrint.printOnConsole('Chat user saved: ${user.id} - ${user.nickname}');
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error saving chat user ${user.id}: $e');
      return false;
    }
  }

  // Save multiple chat users
  Future<bool> saveChatUsers(List<ChatUserModel> users) async {
    try {
      final box = await _openBox();
      if (box == null) return false;

      final Map<String, Map<String, dynamic>> usersMap = {};
      for (final user in users) {
        usersMap[user.id] = user.toMap();
      }

      await box.putAll(usersMap);
      MyPrint.printOnConsole('Saved ${users.length} chat users');
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error saving chat users: $e');
      return false;
    }
  }

  // Get all chat users
  Future<List<ChatUserModel>> getAllChatUsers() async {
    try {
      final box = await _openBox();
      if (box == null || box.isEmpty) return [];

      final List<ChatUserModel> users = [];
      for (final entry in box.toMap().entries) {
        try {
          final user = ChatUserModel.fromMap(
            Map<String, dynamic>.from(entry.value),
          );
          users.add(user);
        } catch (e) {
          MyPrint.printOnConsole('Error parsing chat user ${entry.key}: $e');
        }
      }

      // Sort by most recent interaction or by name
      users.sort((a, b) => a.nickname.compareTo(b.nickname));

      MyPrint.printOnConsole(
        'Retrieved ${users.length} chat users from storage',
      );
      return users;
    } catch (e) {
      MyPrint.printOnConsole('Error getting chat users: $e');
      return [];
    }
  }

  // Get a specific chat user by ID
  Future<ChatUserModel?> getChatUser(String userId) async {
    try {
      final box = await _openBox();
      if (box == null) return null;

      final userData = box.get(userId);
      if (userData == null) return null;

      return ChatUserModel.fromMap(Map<String, dynamic>.from(userData));
    } catch (e) {
      MyPrint.printOnConsole('Error getting chat user $userId: $e');
      return null;
    }
  }

  // Remove a chat user
  Future<bool> removeChatUser(String userId) async {
    try {
      final box = await _openBox();
      if (box == null) return false;

      await box.delete(userId);
      MyPrint.printOnConsole('Chat user removed: $userId');
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error removing chat user $userId: $e');
      return false;
    }
  }

  // Clear all chat users
  Future<bool> clearAllChatUsers() async {
    try {
      final box = await _openBox();
      if (box == null) return false;

      await box.clear();
      MyPrint.printOnConsole('All chat users cleared');
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error clearing chat users: $e');
      return false;
    }
  }

  // Update user's last message info (for chat list sorting)
  Future<bool> updateUserLastMessage({
    required String userId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) async {
    try {
      final user = await getChatUser(userId);
      if (user == null) return false;
      user.lastMessage = lastMessage;
      user.lastMessageTime = lastMessageTime.toIso8601String();

      return await saveChatUser(user);
      // // Assuming ChatUserModel has lastMessage and lastMessageTime fields
      // // If not, you'll need to add them to your model
      // ChatUserModel updatedUser = ChatUserModel(
      //   id: user.id,
      //   name: user.name,
      //   avatar: user.avatar,
      //   isOnline: user.isOnline,
      //   unreadCount: user.unreadCount,
      // );
      //
      // return await saveChatUser(updatedUser);
    } catch (e) {
      MyPrint.printOnConsole('Error updating user last message: $e');
      return false;
    }
  }

  // Get chat users count
  Future<int> getChatUsersCount() async {
    final box = await _openBox();
    return box?.length ?? 0;
  }

  // Close the box
  Future<void> closeBox() async {
    try {
      if (_chatUsersBox?.isOpen == true) {
        await _chatUsersBox?.close();
      }
    } catch (e) {
      MyPrint.printOnConsole('Error closing chat users box: $e');
    }
  }
}
