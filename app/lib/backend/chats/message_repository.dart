import 'dart:io';

import 'package:e2ee_android_app/models/chats/chat_message_model.dart';

import 'package:e2ee_android_app/managers/hive_manager.dart';
import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:hive/hive.dart';

class MessageRepository {
  Future<Box?> _openBox(String chatId) {
    return HiveManager().openBox(
      boxName:
          'messages_'
          '$chatId',
    );
  }

  Future<void> addMessage({required String chatId, required ChatMessageModel message}) async {
    final box = await _openBox(chatId);
    try {
      if (box == null) {
        MyPrint.printOnConsole('Hive box for $chatId is null! Message not saved.');
        return;
      }
      final key = message.id;
      if (key.isEmpty) {
        MyPrint.printOnConsole("Message ID is empty, skipping save.");
        return;
      }

      // Decode and save file if message is not text
      // if (message.message.isNotEmpty) {
      //   try {
      //     final messageData = (message.message);
      //     final type = messageData['type'];

      //     if (type != 'text') {
      //       final fileName = messageData['fileName'];
      //       final base64String = messageData['base64String'];
      //       final fileBytes = base64Decode(base64String);
      //       final filePath = await MyUtils.saveFileToDevice(fileBytes, fileName);
      //       message.message = filePath;
      //     } else {
      //       message.message = messageData['text'];
      //     }
      //   } catch (e) {
      //     // Not a JSON, so it's a plain text message
      //   }
      // }

      if (!box.containsKey(key)) {
        await box.put(key, message.toMap());
        MyPrint.printOnConsole('Message saved: ${message.id} - ${message.message}');
      } else {
        MyPrint.printOnConsole('Duplicate message ignored: ${message.id}');
      }
    } catch (e) {
      MyPrint.printOnConsole('Error saving message: $e');
    }
  }

  Future<List<ChatMessageModel>> getMessagesPage({
    required String chatId,
    required int limit,
    required int offset,
    required String currentUserId,
  }) async {
    final box = await _openBox(chatId);
    if (box == null) return [];
    final entries = box.toMap().entries.toList();

    entries.sort((a, b) {
      final at = DateTime.tryParse(a.value['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = DateTime.tryParse(b.value['timestamp'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    final page = entries.skip(offset).take(limit).toList();

    for (var entry in page) {
      MyPrint.printOnConsole('MMMessage Data: ${entry.value}');
    }

    return page.map((e) => ChatMessageModel.fromMap(Map<String, dynamic>.from(e.value), currentUserId: currentUserId)).toList();
  }

  Stream<ChatMessageModel?> watchMessages({required String chatId, required String currentUserId}) async* {
    final box = await _openBox(chatId);
    if (box == null) return;
    await for (final event in box.watch()) {
      if (event.value != null) {
        yield ChatMessageModel.fromMap(Map<String, dynamic>.from(event.value), currentUserId: currentUserId);
      }
    }
  }

  Future<void> clearMessages(String chatId) async {
    final box = await _openBox(chatId);
    try {
      await box?.clear();
      MyPrint.printOnConsole('Cleared messages for chat: $chatId');
    } catch (e) {
      MyPrint.printOnConsole('Error clearing messages for $chatId: $e');
    }
  }

  Future<void> deleteChat(String chatId) async {
    final box = await _openBox(chatId);
    try {
      await box?.deleteFromDisk();
      MyPrint.printOnConsole('Deleted chat box for: $chatId');
    } catch (e) {
      MyPrint.printOnConsole('Error deleting chat $chatId: $e');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    final box = await _openBox(chatId);
    try {
      final messageMap = box?.get(messageId);
      if (messageMap != null) {
        final message = ChatMessageModel.fromMap(Map<String, dynamic>.from(messageMap), currentUserId: '');

        // If the message is a file path, delete the file
        final file = File(message.message.base64String);
        if (await file.exists()) {
          // Check if it's a file path by checking if it has a file extension
          if (message.message.base64String.contains('.')) {
            await file.delete();
          }
        }
      }
      await box?.delete(messageId);
      MyPrint.printOnConsole('Deleted message: $messageId');
    } catch (e) {
      MyPrint.printOnConsole('Error deleting message $messageId: $e');
    }
  }
}
