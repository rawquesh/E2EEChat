import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';

import 'chat_repository.dart';
import 'chats_provider.dart';

class ChatController {
  late ChatProvider _chatProvider;
  late ChatRepository _chatRepository;

  ChatController({ChatProvider? chatProvider, ChatRepository? repository}) {
    _chatProvider = chatProvider ?? ChatProvider();
    _chatRepository = repository ?? ChatRepository();
  }

  ChatProvider get chatProvider => _chatProvider;
  ChatRepository get chatRepository => _chatRepository;

  Future<bool> searchUser(String username) async {
    try {
      final token = await SharedPrefManager()
          .getString(MySharedPreferenceVariables.authToken);
      if (token == null || token.isEmpty) return false;
      final chatUser = await _chatRepository.fetchChatUser(
        username: username,
        token: token,
      );
      if (chatUser != null) {
        _chatProvider.chatUsers
            .setList(list: [chatUser], isClear: true, isNotify: true);
        _chatProvider.currentOpponent.set(value: chatUser, isNotify: true);
        return true;
      }
      return false;
    } catch (e) {
      MyPrint.printOnConsole('Error searching user: $e');
      return false;
    }
  }

  Future<bool> sendMessage({required String message}) async {
    final opponent = _chatProvider.currentOpponent.get();
    if (opponent == null) return false;
    final token = await SharedPrefManager()
        .getString(MySharedPreferenceVariables.authToken);
    if (token == null || token.isEmpty) return false;
    return _chatRepository.sendMessage(
      token: token,
      chatId: opponent.id,
      message: message,
    );
  }
}