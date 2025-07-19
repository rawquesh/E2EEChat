import 'package:e2ee_models_app/backend/common/common_provider.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';

enum SearchState { initial, loading, success, empty, error }

class ChatProvider extends CommonProvider {
  ChatProvider() {
    chatUsers = CommonProviderListParameter<ChatUserModel>(
      list: <ChatUserModel>[],
      notify: notify,
    );
    currentOpponent = CommonProviderPrimitiveParameter<ChatUserModel?>(
      value: null,
      notify: notify,
    );
    // ✨ INITIALIZE the new state parameter.
    searchState = CommonProviderPrimitiveParameter<SearchState>(
      value: SearchState.initial,
      notify: notify,
    );

    messages = CommonProviderMapParameter<String, List<ChatMessageModel>>(
      map: <String, List<ChatMessageModel>>{},
      notify: notify,
    );
  }

  late CommonProviderListParameter<ChatUserModel> chatUsers;
  late CommonProviderPrimitiveParameter<ChatUserModel?> currentOpponent;
  late CommonProviderMapParameter<String, List<ChatMessageModel>> messages;

  // ✨ ADD a parameter to hold the current search state.
  late CommonProviderPrimitiveParameter<SearchState> searchState;

  void reset() {
    chatUsers.setList(list: <ChatUserModel>[], isClear: true, isNotify: false);
    currentOpponent.set(value: null, isNotify: false);
    // ✨ RESET the search state when needed.
    searchState.set(value: SearchState.initial, isNotify: true);
    messages.setMap(map: <String, List<ChatMessageModel>>{}, isClear: true, isNotify: false);
  }

  /// Retrieve all stored messages for a given user
  List<ChatMessageModel> getMessagesFor(String userId) {
    return messages.getMap()[userId] ?? <ChatMessageModel>[];
  }

  /// Append a message to the list for a user
  void addMessageFor(String userId, ChatMessageModel message) {
    final current = Map<String, List<ChatMessageModel>>.from(messages.getMap());
    final list = List<ChatMessageModel>.from(current[userId] ?? <ChatMessageModel>[]);
    list.add(message);
    current[userId] = list;
    messages.setMap(map: current, isClear: true, isNotify: true);
  }
}