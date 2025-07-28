import 'dart:async';
import 'dart:io';

import 'package:e2ee_android_app/configs/constants.dart';
import 'package:e2ee_models_app/models/chats/chat_message_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:hive/hive.dart';

class SelfDestructService {
  Timer? _timer;
  bool _isRunning = false;
  Function(String chatId, List<ChatMessageModel> deletedMessages)?
  onMessagesDeleted;

  void start({
    required Function(String, List<ChatMessageModel>)?
    onMessagesDeletedCallback,
  }) {
    if (_isRunning) return;

    MyPrint.printOnConsole('[SelfDestructService] Starting...');
    _isRunning = true;
    onMessagesDeleted = onMessagesDeletedCallback;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForExpiredMessages();
    });
    _checkForExpiredMessages(); // Initial check
  }

  void stop() {
    if (!_isRunning) return;

    MyPrint.printOnConsole('[SelfDestructService] Stopping...');
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _checkForExpiredMessages() async {
    MyPrint.printOnConsole(
      '[SelfDestructService] Checking for expired messages...',
    );

    try {
      final chatUsersBox = await Hive.openBox('chat_users');
      if (chatUsersBox.isEmpty) return;

      final chatIds = chatUsersBox.keys.cast<String>();

      for (final chatId in chatIds) {
        final messageBox = await Hive.openBox('messages_$chatId');
        if (messageBox.isEmpty) continue;

        final List<String> keysToDelete = [];
        final List<ChatMessageModel> deletedMessages = [];
        final now = DateTime.now();

        final allMessageKeys = List.from(messageBox.keys);

        for (final key in allMessageKeys) {
          try {
            final messageMap = Map<String, dynamic>.from(messageBox.get(key));
            final message = ChatMessageModel.fromMap(
              messageMap,
              currentUserId: '',
            );

            if (now.isAfter(message.destructTimestamp)) {
              if (message.message.startsWith(imageTypeChat) ||
                  message.message.startsWith(audioTypeChat) ||
                  message.message.startsWith(videoTypeChat) ||
                  message.message.startsWith(docTypeChat)) {
                final filePath = message.message.split(",").last;
                final file = File(filePath);
                if (await file.exists()) {
                  await file.delete();
                }
              }
              keysToDelete.add(key as String);
              deletedMessages.add(message);
            }
          } catch (e) {
            MyPrint.printOnConsole(
              '[SelfDestructService] Error processing message $key in box messages_$chatId: $e',
            );
          }
        }

        if (keysToDelete.isNotEmpty) {
          await messageBox.deleteAll(keysToDelete);
          MyPrint.printOnConsole(
            '[SelfDestructService] Deleted ${keysToDelete.length} messages from chat: $chatId',
          );

          onMessagesDeleted?.call(chatId, deletedMessages);
        }
      }
    } catch (e) {
      MyPrint.printOnConsole('[SelfDestructService] Check failed: $e');
    }
  }
}
