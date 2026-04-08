import 'package:flutter/foundation.dart';

class CommonProvider extends ChangeNotifier {
  void notify({bool isNotify = true}) {
    if (isNotify) notifyListeners();
  }
}

class CommonProviderListParameter<T> {
  List<T> _list;
  final void Function() notify;

  CommonProviderListParameter({
    required List<T> list,
    required this.notify,
  }) : _list = list;

  List<T> getList({bool isNewInstance = true}) {
    return isNewInstance ? List<T>.from(_list) : _list;
  }

  void setList({required List<T> list, bool isClear = true, bool isNotify = true}) {
    if (isClear) {
      _list.clear();
    }
    _list.addAll(list);
    if (isNotify) notify();
  }

  void insertAtIndex({required int index, required T model, bool isNotify = true}) {
    if (index >= 0 && index <= _list.length) {
      _list.insert(index, model);
      if (isNotify) notify();
    }
  }

  void removeObject({required T model, bool isNotify = true}) {
    _list.remove(model);
    if (isNotify) notify();
  }

  void add(T model, {bool isNotify = true}) {
    _list.add(model);
    if (isNotify) notify();
  }

  void clear({bool isNotify = true}) {
    _list.clear();
    if (isNotify) notify();
  }

  int get length => _list.length;
  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;
}

class CommonProviderMapParameter<K, V> {
  Map<K, V> _map;
  final void Function() notify;

  CommonProviderMapParameter({
    required Map<K, V> map,
    required this.notify,
  }) : _map = map;

  Map<K, V> getMap({bool isNewInstance = true}) {
    return isNewInstance ? Map<K, V>.from(_map) : _map;
  }

  void setMap({required Map<K, V> map, bool isClear = true, bool isNotify = true}) {
    if (isClear) _map.clear();
    _map.addAll(map);
    if (isNotify) notify();
  }

  void clearKey({required K key, bool isNotify = true}) {
    _map.remove(key);
    if (isNotify) notify();
  }

  void clear({bool isNotify = true}) {
    _map.clear();
    if (isNotify) notify();
  }

  V? get(K key) => _map[key];
  bool containsKey(K key) => _map.containsKey(key);
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}

class CommonProviderPrimitiveParameter<T> {
  T _value;
  final void Function() notify;

  CommonProviderPrimitiveParameter({
    required T value,
    required this.notify,
  }) : _value = value;

  T get() => _value;

  void set({required T value, bool isNotify = true}) {
    _value = value;
    if (isNotify) notify();
  }
}
