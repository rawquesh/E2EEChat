import 'package:e2ee_models_app/backend/common/common_provider.dart';
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
  }

  late CommonProviderListParameter<ChatUserModel> chatUsers;
  late CommonProviderPrimitiveParameter<ChatUserModel?> currentOpponent;

  // ✨ ADD a parameter to hold the current search state.
  late CommonProviderPrimitiveParameter<SearchState> searchState;

  void reset() {
    chatUsers.setList(list: <ChatUserModel>[], isClear: true, isNotify: false);
    currentOpponent.set(value: null, isNotify: false);
    // ✨ RESET the search state when needed.
    searchState.set(value: SearchState.initial, isNotify: true);
  }
}