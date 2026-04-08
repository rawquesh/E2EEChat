import 'package:intl/intl.dart';

class ParsingHelper {
  static String parseStringMethod(dynamic value, {String defaultValue = ""}) {
    return value?.toString() ?? defaultValue;
  }

  static int parseIntMethod(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return double.tryParse(value)?.toInt() ?? defaultValue;
    return defaultValue;
  }

  static double parseDoubleMethod(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool parseBoolMethod(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == "true") return true;
      if (value.toLowerCase() == "false") return false;
      return defaultValue;
    }
    return defaultValue;
  }

  static List<T2> parseListMethod<T1, T2>(dynamic value, {List<T2>? defaultValue}) {
    defaultValue ??= <T2>[];

    if (value == null) return defaultValue;
    if (value is List) {
      try {
        List<T2?> list = value.map((e) => parseValue<T2>(e) as T2).toList();
        list.removeWhere((e) => e == null);
        return list.map<T2>((e) => e!).toList();
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  static Map<K2, V2> parseMapMethod<K1, V1, K2, V2>(dynamic value, {Map<K2, V2>? defaultValue}) {
    defaultValue ??= <K2, V2>{};

    if (value == null) return defaultValue;
    if (value is Map) {
      try {
        Map<K2, V2> newMap2 = <K2, V2>{};
        for (var value1 in value.entries) {
          K2? parsedKey = parseValue<K2>(value1.key);
          V2? parsedValue = parseValue<V2>(value1.value);
          if (parsedKey is K2 && parsedValue is V2) {
            newMap2[parsedKey] = parsedValue;
          }
        }
        return newMap2;
      } catch (e) {
        return defaultValue;
      }
    }
    return defaultValue;
  }

  static DateTime? parseDateTimeMethod(
    dynamic value, {
    DateTime? defaultValue,
    String? dateFormat,
  }) {
    if (value == null) return defaultValue;

    try {
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        if (dateFormat?.isNotEmpty ?? false) {
          try {
            return DateFormat(dateFormat!).parse(value);
          } catch (_) {}
        }
        int? millis = int.tryParse(value);
        if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
        return DateTime.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static List<Map<K, V>> parseMapsListMethod<K, V>(dynamic value, {List<Map<K, V>>? defaultValue, bool isEmptyMapAllowed = false}) {
    defaultValue ??= <Map<K, V>>[];
    List list = parseListMethod(value);
    List<Map<K, V>> mapsList = <Map<K, V>>[];
    for (dynamic value in list) {
      Map<K, V> map = parseMapMethod<dynamic, dynamic, K, V>(value);
      if (isEmptyMapAllowed || map.isNotEmpty) {
        mapsList.add(map);
      }
    }
    return mapsList;
  }

  static String? parseStringNullableMethod(dynamic value, {String? defaultValue}) {
    return value?.toString() ?? defaultValue;
  }

  static int? parseIntNullableMethod(dynamic value, {int? defaultValue}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double? parseDoubleNullableMethod(dynamic value, {double? defaultValue}) {
    if (value == null) return defaultValue;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static bool? parseBoolNullableMethod(dynamic value, {bool? defaultValue}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == "true") return true;
      if (value.toLowerCase() == "false") return false;
      return defaultValue;
    }
    return defaultValue;
  }

  static T? parseValue<T>(dynamic value, {T? defaultValue}) {
    try {
      T? parsedValue = switch (T.toString()) {
        "dynamic" => value as T,
        "String" => parseStringMethod(value) as T,
        "int" => parseIntMethod(value) as T,
        "double" => parseDoubleMethod(value) as T,
        "bool" => parseBoolMethod(value) as T,
        "String?" => parseStringNullableMethod(value) as T,
        "int?" => parseIntNullableMethod(value) as T,
        "double?" => parseDoubleNullableMethod(value) as T,
        "bool?" => parseBoolNullableMethod(value) as T,
        "List" => parseListMethod(value) as T,
        "List<String>" => parseListMethod<dynamic, String>(value) as T,
        "List<int>" => parseListMethod<dynamic, int>(value) as T,
        "List<double>" => parseListMethod<dynamic, double>(value) as T,
        "List<bool>" => parseListMethod<dynamic, bool>(value) as T,
        "Map<String, dynamic>" => parseMapMethod<dynamic, dynamic, String, dynamic>(value) as T,
        _ => defaultValue,
      };
      return parsedValue;
    } catch (e) {
      return defaultValue;
    }
  }
}
