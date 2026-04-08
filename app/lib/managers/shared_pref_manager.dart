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
    return (_prefs?.containsKey(key) ?? false) ? _prefs!.getBool(key) : null;
  }

  Future<bool?> clearKey(String key) async {
    _prefs = await _getInstance();
    return (_prefs?.containsKey(key) ?? false) ? _prefs!.remove(key) : null;
  }

  Future<bool> clearAll() async {
    _prefs = await _getInstance();
    return _prefs?.clear() ?? Future.value(false);
  }
}
