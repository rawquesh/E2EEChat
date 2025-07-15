import 'package:flutter/foundation.dart';

class CommonProvider extends ChangeNotifier {
  void notify({bool isNotify = true}) {
    if (isNotify) notifyListeners();
  }
}

typedef NewListInstancialization<T> = T Function(T);
typedef NewMapInstancialization<K, V> = MapEntry<K, V> Function(MapEntry<K, V>);

class CommonProviderListParameter<T> {
  late void Function({bool isNotify}) _notify;
  NewListInstancialization<T>? _newInstancialization;

  CommonProviderListParameter({
    required List<T> list,
    required void Function({bool isNotify}) notify,
    NewListInstancialization<T>? newInstancialization,
  }) {
    _notify = notify;
    _newInstancialization = newInstancialization;
    setList(list: list, isClear: true, isNotify: false);
  }

  final List<T> _list = <T>[];

  int get length => _list.length;

  List<T> getList({
    bool isNewInstance = true,
  }) {
    if (isNewInstance) {
      return _list.map((e) {
        if (_newInstancialization != null) {
          return _newInstancialization!(e);
        } else {
          return e;
        }
      }).toList();
    } else {
      return _list;
    }
  }

  void setList({required List<T> list, bool isClear = true, bool isNotify = true}) {
    if (isClear) _list.clear();
    _list.addAll(list);
    _notify(isNotify: isNotify);
  }

  T? elementAtIndex(int index) {
    if (index >= 0 && index < length) {
      return _list[index];
    }
    return null;
  }

  void insertAtIndex({required int index, required T model, bool isNotify = true}) {
    _list.insert(index, model);
    _notify(isNotify: isNotify);
  }

  void removeObject({required T model, bool isNotify = true}) {
    _list.remove(model);
    _notify(isNotify: isNotify);
  }

  void insertAll({required int index, required List<T> list, bool isNotify = true}) {
    _list.insertAll(index, list);
    _notify(isNotify: isNotify);
  }
}

class CommonProviderMapParameter<K, V> {
  late void Function({bool isNotify}) _notify;
  NewMapInstancialization<K, V>? _newInstancialization;

  CommonProviderMapParameter({
    required Map<K, V> map,
    required void Function({bool isNotify}) notify,
    NewMapInstancialization<K, V>? newInstancialization,
  }) {
    _notify = notify;
    _newInstancialization = newInstancialization;
    setMap(map: map, isClear: true, isNotify: false);
  }

  final Map<K, V> _map = <K, V>{};

  int get length => _map.length;

  Map<K, V> getMap({
    bool isNewInstance = true,
  }) {
    if (isNewInstance) {
      return _map.map((K key, V value) {
        MapEntry<K, V> mapEntry = MapEntry<K, V>(key, value);

        if (_newInstancialization != null) {
          return _newInstancialization!(mapEntry);
        } else {
          return mapEntry;
        }
      });
    } else {
      return _map;
    }
  }

  void setMap({required Map<K, V> map, bool isClear = true, bool isNotify = true}) {
    if (isClear) _map.clear();
    _map.addAll(map);
    _notify(isNotify: isNotify);
  }

  void clearKey({required String key, bool isNotify = true}) {
    _map.remove(key);
    _notify(isNotify: isNotify);
  }

  void clearKeys({required List<String> keys, bool isNotify = true}) {
    _map.removeWhere((key, value) => keys.contains(key));
    _notify(isNotify: isNotify);
  }
}

class CommonProviderPrimitiveParameter<T> {
  late void Function({bool isNotify}) _notify;

  CommonProviderPrimitiveParameter({
    required T value,
    required void Function({bool isNotify}) notify,
  }) {
    _notify = notify;
    set(value: value, isNotify: false);
  }

  late T _value;

  T get() {
    return _value;
  }

  void set({required T value, bool isNotify = true}) {
    _value = value;
    _notify(isNotify: isNotify);
  }
}
