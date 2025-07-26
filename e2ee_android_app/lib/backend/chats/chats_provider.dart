import 'package:e2ee_models_app/backend/common/common_provider.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/models/chats/chat_user_model.dart';

enum SearchState { initial, loading, success, empty, error }

class DeletionEvent {
  final String chatId;
  final List<ChatMessageModel> deletedMessages;

  DeletionEvent(this.chatId, this.deletedMessages);
}

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
    searchState = CommonProviderPrimitiveParameter<SearchState>(
      value: SearchState.initial,
      notify: notify,
    );

    messages = CommonProviderMapParameter<String, List<ChatMessageModel>>(
      map: <String, List<ChatMessageModel>>{},
      notify: notify,
    );
  }

  DeletionEvent? _lastDeletedMessages;

  DeletionEvent? get lastDeletedMessages => _lastDeletedMessages;

  late CommonProviderListParameter<ChatUserModel> chatUsers;
  late CommonProviderPrimitiveParameter<ChatUserModel?> currentOpponent;
  late CommonProviderMapParameter<String, List<ChatMessageModel>> messages;
  late CommonProviderPrimitiveParameter<SearchState> searchState;

  void reset() {
    chatUsers.setList(list: <ChatUserModel>[], isClear: true, isNotify: false);
    currentOpponent.set(value: null, isNotify: false);
    searchState.set(value: SearchState.initial, isNotify: false);
    messages.setMap(
      map: <String, List<ChatMessageModel>>{},
      isClear: true,
      isNotify: false,
    );
    notifyListeners();
  }

  void resetSearch() {
    searchState.set(value: SearchState.initial, isNotify: true);
  }

  List<ChatMessageModel> getMessagesFor(String userId) {
    return messages.getMap()[userId] ?? <ChatMessageModel>[];
  }

  void addMessageFor(String userId, ChatMessageModel message) {
    final current = Map<String, List<ChatMessageModel>>.from(messages.getMap());
    final list = List<ChatMessageModel>.from(
      current[userId] ?? <ChatMessageModel>[],
    );
    final exists = list.any((m) => m.id == message.id);
    if (!exists) list.add(message);
    current[userId] = list;
    messages.setMap(map: current, isClear: true, isNotify: true);
  }

  void clearMessagesFor(String userId) {
    final current = Map<String, List<ChatMessageModel>>.from(messages.getMap());
    if (current.containsKey(userId)) {
      current.remove(userId);
      messages.setMap(map: current, isClear: true, isNotify: true);
    }
  }

  // ✨ FIX: This method now correctly handles both initial loads and pagination.
  void addMessagesFor(
    String userId,
    List<ChatMessageModel> newMessages, {
    bool clear = false,
  }) {
    final current = Map<String, List<ChatMessageModel>>.from(messages.getMap());
    final list = List<ChatMessageModel>.from(
      current[userId] ?? <ChatMessageModel>[],
    );

    if (clear) {
      // For an initial load, clear the list and add the new messages.
      list.clear();
      list.addAll(newMessages);
    } else {
      // For pagination (loading older messages), insert them at the beginning.
      list.insertAll(0, newMessages);
    }

    // De-duplicate messages to be safe
    final seen = <String>{};
    final uniqueList = <ChatMessageModel>[];
    for (final msg in list) {
      if (seen.add(msg.id)) {
        uniqueList.add(msg);
      }
    }

    // Sort the final list by timestamp to ensure correct order
    uniqueList.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    current[userId] = uniqueList;
    messages.setMap(map: current, isClear: true, isNotify: true);
  }

  void clearLastDeletedEvent() {
    _lastDeletedMessages = null;
    // Do not notify listeners here, as it's just a cleanup
  }

  void removeMessages(String userId, List<ChatMessageModel> messagesToRemove) {
    final current = Map<String, List<ChatMessageModel>>.from(messages.getMap());
    if (current.containsKey(userId)) {
      final list = List<ChatMessageModel>.from(current[userId]!);
      final idsToRemove = messagesToRemove.map((m) => m.id).toSet();
      list.removeWhere((msg) => idsToRemove.contains(msg.id));
      current[userId] = list;
      messages.setMap(map: current, isClear: true, isNotify: false);

      _lastDeletedMessages = DeletionEvent(userId, messagesToRemove);
      notifyListeners();
    }
  }
}
