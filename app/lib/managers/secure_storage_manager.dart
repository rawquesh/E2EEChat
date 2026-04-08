import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/my_print.dart';

class SecureStorageManager {
  SecureStorageManager._();

  static final SecureStorageManager _instance = SecureStorageManager._();

  factory SecureStorageManager() => _instance;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> setString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      MyPrint.printOnConsole('Error writing to secure storage: $e');
    }
  }

  Future<String?> getString(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      MyPrint.printOnConsole('Error reading from secure storage: $e');
      return null;
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      MyPrint.printOnConsole('Error deleting from secure storage: $e');
    }
  }

  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      MyPrint.printOnConsole('Error deleting all from secure storage: $e');
    }
  }

  Future<Map<String, String>> readAll() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      MyPrint.printOnConsole('Error reading all from secure storage: $e');
      return {};
    }
  }
}
