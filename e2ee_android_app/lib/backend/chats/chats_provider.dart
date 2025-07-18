import 'package:e2ee_models_app/backend/common/common_provider.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';

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
  }

  late CommonProviderListParameter<ChatUserModel> chatUsers;
  late CommonProviderPrimitiveParameter<ChatUserModel?> currentOpponent;

  void reset() {
    chatUsers.setList(list: <ChatUserModel>[], isClear: true, isNotify: false);
    currentOpponent.set(value: null, isNotify: true);
  }
}