import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';

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

  Future<bool> sendMessage({required String message}) async {
    final opponent = _chatProvider.currentOpponent.get();
    if (opponent == null) return false;
    final token = await SharedPrefManager().getString(MySharedPreferenceVariables.authToken);
    final senderId = await SharedPrefManager().getString('current_user_id');
    final receiverId = opponent.id;
    if (token == null || token.isEmpty || senderId == null || senderId.isEmpty) return false;
    return _chatRepository.sendMessage(
      token: token,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
    );
  }

  Future<void> saveLocalMessage({
    required String chatId,
    required ChatMessageModel message,
  }) async {
    await _messageRepository.addMessage(chatId: chatId, message: message);
  }

  Future<List<ChatMessageModel>> fetchMessagesPage({
    required String chatId,
    required int limit,
    required int offset,
    required String currentUserId,
  }) {
    return _messageRepository.getMessagesPage(
      chatId: chatId,
      limit: limit,
      offset: offset,
      currentUserId: currentUserId,
    );
  }

  Stream<ChatMessageModel?> watchMessages({
    required String chatId,
    required String currentUserId,
  }) {
    return _messageRepository.watchMessages(
      chatId: chatId,
      currentUserId: currentUserId,
    );
  }

  Future<bool> loadStoredChatUsers() async {
    try {
      final storedUsers = await _chatUsersRepository.getAllChatUsers();
      if (storedUsers.isNotEmpty) {
        _chatProvider.chatUsers.setList(
            list: storedUsers,
            isClear: true,
            isNotify: true
        );
        _chatProvider.searchState.set(
            value: SearchState.success,
            isNotify: true
        );
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
      final token = await SharedPrefManager()
          .getString(MySharedPreferenceVariables.authToken);
      MyPrint.printOnConsole("Token retrieved: $token");
      if (token == null || token.isEmpty) return false;

      final chatUser = await _chatRepository.fetchChatUser(
        username: username,
        token: token,
      );

      if (chatUser != null) {
        // Save the user to Hive
        await _chatUsersRepository.saveChatUser(chatUser);

        // Update provider
        _chatProvider.chatUsers.setList(
            list: [chatUser],
            isClear: true,
            isNotify: true
        );
        _chatProvider.currentOpponent.set(value: chatUser, isNotify: true);
        _chatProvider.searchState.set(value: SearchState.success, isNotify: true);

        MyPrint.printOnConsole('User found and saved: ${chatUser.name}');
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

  // Method to add a user to the chat list (when starting a new conversation)
  Future<bool> addUserToChatList(ChatUserModel user) async {
    try {
      // Save to Hive
      final saved = await _chatUsersRepository.saveChatUser(user);
      MyPrint.printOnConsole('User saved to Hive: ${user.name} - $saved');
      if (saved) {
        // Update provider
        final currentUsers = _chatProvider.chatUsers.getList();

        // Check if user already exists
        final existingIndex = currentUsers.indexWhere((u) => u.id == user.id);
        if (existingIndex == -1) {
          // Add new user
          currentUsers.add(user);
        } else {
          // Update existing user
          currentUsers[existingIndex] = user;
        }

        _chatProvider.chatUsers.setList(
            list: currentUsers,
            isClear: true,
            isNotify: true
        );

        MyPrint.printOnConsole('User added to chat list: ${user.name}');
        return true;
      }
      return false;
    } catch (e) {
      MyPrint.printOnConsole('Error adding user to chat list: $e');
      return false;
    }
  }

  // Update user's last message (for chat list preview)
  Future<void> updateUserLastMessage({
    required String userId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) async {
    // Update in persistent storage (e.g., Hive or DB)
    await _chatUsersRepository.updateUserLastMessage(
      userId: userId,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
    );

    // Update in provider (for UI)
    final List<ChatUserModel> currentUsers = List.from(_chatProvider.chatUsers.getList());
    final int userIndex = currentUsers.indexWhere((u) => u.id == userId);

    if (userIndex != -1) {
      final updatedUser = ChatUserModel(
        id: currentUsers[userIndex].id,
        name: currentUsers[userIndex].name,
        avatar: currentUsers[userIndex].avatar,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime.toIso8601String(),
        isOnline: currentUsers[userIndex].isOnline,
        unreadCount: currentUsers[userIndex].unreadCount,
      );
      currentUsers[userIndex] = updatedUser;

      // Sort by lastMessageTime if you want recent chats on top
      currentUsers.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      _chatProvider.chatUsers.setList(
        list: currentUsers,
        isClear: true,
        isNotify: true,
      );
    }
  }

  // Remove user from chat list
  Future<bool> removeUserFromChatList(String userId) async {
    try {
      final removed = await _chatUsersRepository.removeChatUser(userId);
      if (removed) {
        final currentUsers = _chatProvider.chatUsers.getList();
        currentUsers.removeWhere((u) => u.id == userId);
        _chatProvider.chatUsers.setList(
            list: currentUsers,
            isClear: true,
            isNotify: true
        );
        return true;
      }
      return false;
    } catch (e) {
      MyPrint.printOnConsole('Error removing user from chat list: $e');
      return false;
    }
  }

  // Clear all chat data
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
}