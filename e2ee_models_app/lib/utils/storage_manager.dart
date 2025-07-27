import 'package:e2ee_models_app/utils/my_print.dart' show MyPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefManager {
  static SharedPrefManager? _instance;
  SharedPreferences? _prefs;

  factory SharedPrefManager() {
    _instance ??= SharedPrefManager._();
    return _instance!;
  }

  SharedPrefManager._();

  Future<SharedPreferences?> _getInstance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> setString(String key, String value) async {
    _prefs = await _getInstance();
    return _prefs?.setString(key, value) ?? Future.value(false);
  }

  Future<bool> setInt(String key, int value) async {
    _prefs = await _getInstance();
    return _prefs?.setInt(key, value) ?? Future.value(false);
  }

  Future<bool> setDouble(String key, double value) async {
    _prefs = await _getInstance();
    return _prefs?.setDouble(key, value) ?? Future.value(false);
  }

  Future<bool> setBool(String key, bool value) async {
    _prefs = await _getInstance();
    return _prefs?.setBool(key, value) ?? Future.value(false);
  }

  Future<String?> getString(String key) async {
    _prefs = await _getInstance();
    return (_prefs?.containsKey(key) ?? false) ? _prefs!.getString(key) : null;
  }

  Future<int?> getInt(String key) async {
    _prefs = await _getInstance();
    return (_prefs?.containsKey(key) ?? false) ? _prefs!.getInt(key) : null;
  }

  Future<double?> getDouble(String key) async {
    _prefs = await _getInstance();
    return (_prefs?.containsKey(key) ?? false) ? _prefs?.getDouble(key) : null;
  }

  Future<bool?> getBool(String key) async {
    _prefs = await _getInstance();
    return (_prefs?.containsKey(key) ?? false) ? _prefs?.getBool(key) : null;
  }

  Future<bool?> clearKey(String key) async {
    _prefs = await _getInstance();
    return (_prefs?.containsKey(key) ?? false) ? _prefs?.remove(key) : null;
  }

  Future<bool> clearAll() async {
    _prefs = await _getInstance();
    return _prefs?.clear() ?? Future.value(false);
  }
}


class SecureStorageManager {
  SecureStorageManager._();

  static final SecureStorageManager _instance = SecureStorageManager._();

  factory SecureStorageManager() {
    return _instance;
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> setString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      MyPrint.printOnConsole('Error writing to secure storage: $e');
    }
  }

  Future<String?> getString( String key) async {
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