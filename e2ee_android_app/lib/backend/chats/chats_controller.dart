import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';

import 'chat_repository.dart';
import 'chat_users_repository.dart';
import 'chats_provider.dart';
import 'message_repository.dart';

class ChatController {
  late ChatProvider _chatProvider;
  late ChatRepository _chatRepository;
  late MessageRepository _messageRepository;
  late ChatUsersRepository _chatUsersRepository;

  ChatController({
    ChatProvider? chatProvider,
    ChatRepository? repository,
    MessageRepository? messageRepository,
    ChatUsersRepository? chatUsersRepository,
  }) {
    _chatProvider = chatProvider ?? ChatProvider();
    _chatRepository = repository ?? ChatRepository();
    _messageRepository = messageRepository ?? MessageRepository();
    _chatUsersRepository = chatUsersRepository ?? ChatUsersRepository();
  }

  ChatProvider get chatProvider => _chatProvider;

  ChatRepository get chatRepository => _chatRepository;

  MessageRepository get messageRepository => _messageRepository;

  ChatUsersRepository get chatUsersRepository => _chatUsersRepository;

  Future<bool> sendMessage({required String message, required int destructTimer}) async {
    final opponent = _chatProvider.currentOpponent.get();
    if (opponent == null) return false;
    final token = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken);
    final senderId = await SharedPrefManager().getString(MySharedPreferenceVariables.currentUserId);
    final username = await SharedPrefManager().getString(MySharedPreferenceVariables.username) ?? 'Unknown';
    final nickname = await SharedPrefManager().getString(MySharedPreferenceVariables.nickname) ?? 'UnknownName';
    final receiverId = opponent.id;
    if (token == null || token.isEmpty || senderId == null || senderId.isEmpty) return false;
    return _chatRepository.sendMessage(
      token: token,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      username: username,
      nickname: nickname, 
      destructTimer: destructTimer,
    );
  }

  Future<void> saveMessageToHive({required String chatId, required ChatMessageModel message}) async {
    await _messageRepository.addMessage(chatId: chatId, message: message);
  }

  Future<List<ChatMessageModel>> fetchMessagesPage({required String chatId, required int limit, required int offset, required String currentUserId}) {
    return _messageRepository.getMessagesPage(chatId: chatId, limit: limit, offset: offset, currentUserId: currentUserId);
  }

  Stream<ChatMessageModel?> watchMessages({required String chatId, required String currentUserId}) {
    return _messageRepository.watchMessages(chatId: chatId, currentUserId: currentUserId);
  }

  Future<bool> loadStoredChatUsers() async {
    try {
      final storedUsers = await _chatUsersRepository.getAllChatUsers();
      // Sort users by last message time, newest first
      storedUsers.sort((a, b) => DateTime.parse(b.lastMessageTime).compareTo(DateTime.parse(a.lastMessageTime)));

      if (storedUsers.isNotEmpty) {
        _chatProvider.chatUsers.setList(list: storedUsers, isClear: true, isNotify: true);
        _chatProvider.searchState.set(value: SearchState.success, isNotify: true);
        MyPrint.printOnConsole('Loaded ${storedUsers.length} stored chat users');
        return true;
      }
      return false;
    } catch (e) {
      MyPrint.printOnConsole('Error loading stored chat users: $e');
      return false;
    }
  }

  Future<bool> searchUser(String username) async {
    MyPrint.printOnConsole("searchUser called with username: $username");

    _chatProvider.searchState.set(value: SearchState.loading, isNotify: true);

    try {
      final token = await SecureStorageManager().getString(MySharedPreferenceVariables.authToken);
      MyPrint.printOnConsole("Token retrieved: $token");
      if (token == null || token.isEmpty) return false;

      final chatUser = await _chatRepository.fetchChatUser(username: username, token: token);

      if (chatUser != null) {
        // Just update the provider to show the temporary search result.
        // await _chatUsersRepository.saveChatUser(chatUser);

        _chatProvider.chatUsers.setList(list: [chatUser], isClear: true, isNotify: true);
        _chatProvider.currentOpponent.set(value: chatUser, isNotify: true);
        _chatProvider.searchState.set(value: SearchState.success, isNotify: true);

        MyPrint.printOnConsole('User found and displayed (not saved yet): ${chatUser.nickname}');
        return true;
      }

      _chatProvider.chatUsers.setList(list: [], isClear: true, isNotify: true);
      _chatProvider.searchState.set(value: SearchState.empty, isNotify: true);
      return false;
    } catch (e) {
      _chatProvider.searchState.set(value: SearchState.error, isNotify: true);
      MyPrint.printOnConsole('Error searching user: $e');
      return false;
    }
  }

  Future<bool> addUserToChatList(ChatUserModel user) async {
    try {
      final saved = await _chatUsersRepository.saveChatUser(user);
      MyPrint.printOnConsole('User saved to Hive: ${user.nickname} - $saved');
      if (saved) {
        final currentUsers = await _chatUsersRepository.getAllChatUsers();
        currentUsers.sort((a, b) => DateTime.parse(b.lastMessageTime).compareTo(DateTime.parse(a.lastMessageTime)));

        _chatProvider.chatUsers.setList(list: currentUsers, isClear: true, isNotify: true);

        MyPrint.printOnConsole('User added/updated in chat list: ${user.nickname}');
        return true;
      }
      return false;
    } catch (e) {
      MyPrint.printOnConsole('Error adding user to chat list: $e');
      return false;
    }
  }

  Future<void> clearUnreadCount(String userId) async {
    try {
      final user = await _chatUsersRepository.getChatUser(userId);
      if (user != null && user.unreadCount > 0) {
        user.unreadCount = 0;
        await _chatUsersRepository.saveChatUser(user);

        // Also update the user in the provider's list for instant UI feedback
        final List<ChatUserModel> currentUsers = List.from(_chatProvider.chatUsers.getList());
        final int userIndex = currentUsers.indexWhere((u) => u.id == userId);
        if (userIndex != -1) {
          currentUsers[userIndex] = user;
          _chatProvider.chatUsers.setList(list: currentUsers, isClear: true, isNotify: true);
        }
      }
    } catch (e) {
      MyPrint.printOnConsole('Error clearing unread count: $e');
    }
  }

  Future<void> updateUserLastMessage({required String userId, required String lastMessage, required DateTime lastMessageTime}) async {
    await _chatUsersRepository.updateUserLastMessage(userId: userId, lastMessage: lastMessage, lastMessageTime: lastMessageTime);
    final List<ChatUserModel> currentUsers = List.from(_chatProvider.chatUsers.getList());
    final int userIndex = currentUsers.indexWhere((u) => u.id == userId);

    if (userIndex != -1) {
      final updatedUser = ChatUserModel(
        id: currentUsers[userIndex].id,
        nickname: currentUsers[userIndex].nickname,
        username: currentUsers[userIndex].username,
        avatar: currentUsers[userIndex].avatar,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime.toIso8601String(),
        isOnline: currentUsers[userIndex].isOnline,
        unreadCount: currentUsers[userIndex].unreadCount,
      );
      currentUsers[userIndex] = updatedUser;
      currentUsers.sort((a, b) => DateTime.parse(b.lastMessageTime).compareTo(DateTime.parse(a.lastMessageTime)));

      _chatProvider.chatUsers.setList(list: currentUsers, isClear: true, isNotify: true);
    }
  }

  Future<bool> removeUserFromChatList(String userId) async {
    try {
      final removed = await _chatUsersRepository.removeChatUser(userId);
      if (removed) {
        final currentUsers = _chatProvider.chatUsers.getList();
        currentUsers.removeWhere((u) => u.id == userId);
        _chatProvider.chatUsers.setList(list: currentUsers, isClear: true, isNotify: true);
        return true;
      }
      return false;
    } catch (e) {
      MyPrint.printOnConsole('Error removing user from chat list: $e');
      return false;
    }
  }

  Future<bool> clearAllChatData() async {
    try {
      await _chatUsersRepository.clearAllChatUsers();
      _chatProvider.chatUsers.setList(list: [], isClear: true, isNotify: true);
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error clearing chat data: $e');
      return false;
    }
  }

  Future<void> loadMessagesToProvider({
    required String chatId,
    required int limit,
    required int offset,
    required String currentUserId,
    bool clear = false,
  }) async {
    try {
      final fetched = await fetchMessagesPage(chatId: chatId, limit: limit, offset: offset, currentUserId: currentUserId);
      final ordered = fetched.reversed.toList();
      _chatProvider.addMessagesFor(chatId, ordered, clear: clear);
    } catch (e) {
      MyPrint.printOnConsole('Error loading messages to provider: $e');
    }
  }

  Future<bool> clearChat(String chatId) async {
    try {
      await _messageRepository.clearMessages(chatId);
      _chatProvider.clearMessagesFor(chatId);
      await updateUserLastMessage(userId: chatId, lastMessage: '', lastMessageTime: DateTime.now());
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error clearing chat $chatId: $e');
      return false;
    }
  }

  Future<bool> deleteChat(String chatId) async {
    try {
      await _messageRepository.deleteChat(chatId);
      await _chatUsersRepository.removeChatUser(chatId);
      _chatProvider.clearMessagesFor(chatId);
      final currentUsers = _chatProvider.chatUsers.getList();
      currentUsers.removeWhere((u) => u.id == chatId);
      _chatProvider.chatUsers.setList(list: currentUsers, isClear: true, isNotify: true);
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error deleting chat $chatId: $e');
      return false;
    }
  }

  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      final message = _chatProvider
          .getMessagesFor(chatId)
          .firstWhere((element) => element.id == messageId);
      message.destructTimestamp = DateTime.now().subtract(Duration(seconds: 1));
      await _messageRepository.addMessage(chatId: chatId, message: message);
      await _messageRepository.deleteMessage(chatId, messageId);
      _chatProvider.removeMessage(chatId, messageId);
      return true;
    } catch (e) {
      MyPrint.printOnConsole('Error deleting message $messageId: $e');
      return false;
    }
  }
}
