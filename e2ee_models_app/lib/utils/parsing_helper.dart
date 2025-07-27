// For Parsing Dynamic Values To Specific Type
import 'package:intl/intl.dart';

// import 'my_print.dart';

class ParsingHelper {
  static String parseStringMethod(dynamic value, {String defaultValue = ""}) {
    return value?.toString() ?? defaultValue;
  }

  static int parseIntMethod(dynamic value, {int defaultValue = 0}) {
    if (value == null) {
      return defaultValue;
    } else if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is String) {
      return double.tryParse(value)?.toInt() ?? defaultValue;
    } else {
      return defaultValue;
    }
  }

  static double parseDoubleMethod(dynamic value, {double defaultValue = 0}) {
    if (value == null) {
      return defaultValue;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    } else {
      return defaultValue;
    }
  }

  static bool parseBoolMethod(dynamic value, {bool defaultValue = false}) {
    if (value == null) {
      return defaultValue;
    } else if (value is bool) {
      return value;
    } else if (value is String) {
      if (value.toLowerCase() == "true") {
        return true;
      } else if (value.toLowerCase() == "false") {
        return false;
      } else {
        return defaultValue;
      }
    } else {
      return defaultValue;
    }
  }

  static List<T2> parseListMethod<T1, T2>(dynamic value, {List<T2>? defaultValue}) {
    defaultValue ??= <T2>[];

    if (value == null) {
      return defaultValue;
    } else if (value is List) {
      try {
        List<T2?> list = value.map((e) => parseValue<T2>(e) as T2).toList();
        list.removeWhere((e) => e == null);

        return list.map<T2>((e) => e!).toList();
      } catch (e) {
        return defaultValue;
      }
    } else {
      return defaultValue;
    }
  }

  static Map<K2, V2> parseMapMethod<K1, V1, K2, V2>(dynamic value, {Map<K2, V2>? defaultValue}) {
    defaultValue ??= <K2, V2>{};

    if (value == null) {
      return defaultValue;
    } else if (value is Map) {
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

        /*Map<K1, V1> newMap = Map.castFrom<dynamic, dynamic, K1, V1>(value);
        Map<K2, V2> newMap2 = Map.castFrom<K1, V1, K2, V2>(newMap);
        return newMap2;*/
      } catch (e) {
        return defaultValue;
      }
    } else {
      return defaultValue;
    }
  }

  /*static DateTime? parseDateTimeMethod(dynamic value, {DateTime? defaultValue, String dateFormat = ""}) {
    if (value is DateTime) {
      return value;
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      DateTime? dateTime;
      MyPrint.printOnConsole("DateTime Value:$value");
      if (dateFormat.isNotEmpty) {
        try {
          dateTime = DateFormat(dateFormat).parse(value);
        } catch (e, s) {
          MyPrint.printOnConsole("Error in Converting from String to DateTime with Format '$dateFormat':$e");
          MyPrint.printOnConsole(s);
        }
      }

      if (dateTime == null) {
        int? intValue = int.tryParse(value);
        if (intValue != null) {
          try {
            dateTime = DateTime.fromMillisecondsSinceEpoch(intValue);
          } catch (e, s) {
            MyPrint.printOnConsole("Error in Converting from String(int) to DateTime:$e");
            MyPrint.printOnConsole(s);
          }
        }
      }

      dateTime ??= DateTime.tryParse(value);

      return dateTime ?? defaultValue;
    } else if (value is int) {
      DateTime? dateTime;

      try {
        dateTime = DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e, s) {
        MyPrint.printOnConsole("Error in Converting from int to DateTime:$e");
        MyPrint.printOnConsole(s);
      }

      return dateTime ?? defaultValue;
    } else {
      return defaultValue;
    }
  }*/

  static DateTime? parseDateTimeMethod(
      dynamic value, {
        DateTime? defaultValue,
        String? dateFormat,
      }) {
    if (value == null) return defaultValue;

    try {
      if (value is DateTime) {
        return value;
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        if (dateFormat?.isNotEmpty ?? false) {
          try {
            return DateFormat(dateFormat!).parse(value);
          } catch (_) {
          }
        }

        int? millis = int.tryParse(value);
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }

        return DateTime.tryParse(value) ?? defaultValue;
      } else {
        return defaultValue;
      }
    } catch (e) {
      return defaultValue;
    }
  }

  static List<Map<K, V>> parseMapsListMethod<K, V>(dynamic value, {List<Map<K, V>>? defaultValue, bool isEmptyMapAllowed = false}) {
    defaultValue ??= <Map<K, V>>[];

    List list = ParsingHelper.parseListMethod(value);
    List<Map<K, V>> mapsList = <Map<K, V>>[];

    for (dynamic value in list) {
      Map<K, V> map = ParsingHelper.parseMapMethod<dynamic, dynamic, K, V>(value);

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
    if (value == null) {
      return defaultValue;
    } else if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    } else {
      return defaultValue;
    }
  }

  static double? parseDoubleNullableMethod(dynamic value, {double? defaultValue}) {
    if (value == null) {
      return defaultValue;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    } else {
      return defaultValue;
    }
  }

  /*static Timestamp? parseTimestampMethod(dynamic value, {DateTime? defaultValue, String dateFormat = ""}) {
    DateTime? dateTime = parseDateTimeMethod(value, defaultValue: defaultValue, dateFormat: dateFormat);

    if (dateTime != null) {
      return Timestamp.fromDate(dateTime);
    } else {
      return null;
    }
  }*/

  static bool? parseBoolNullableMethod(dynamic value, {bool? defaultValue}) {
    if (value == null) {
      return defaultValue;
    } else if (value is bool) {
      return value;
    } else if (value is String) {
      if (value.toLowerCase() == "true") {
        return true;
      } else if (value.toLowerCase() == "false") {
        return false;
      } else {
        return defaultValue;
      }
    } else {
      return defaultValue;
    }
  }

  /*static GeoPoint? parseGeoPointMethod(dynamic value, {GeoPoint? defaultValue}) {
    if (value == null) {
      return defaultValue;
    } else if (value is GeoPoint) {
      return value;
    } else if (value is Map) {
      Map<String, dynamic> map = parseMapMethod<dynamic, dynamic, String, dynamic>(value);
      double? lat = parseDoubleNullableMethod(map['lat']);
      double? lon = parseDoubleNullableMethod(map['lon']);

      if (lat == null || lon == null) {
        return defaultValue;
      }

      return GeoPoint(lat, lon);
    } else {
      return defaultValue;
    }
  }*/

  static T? parseValue<T>(dynamic value, {T? defaultValue}) {
    try {
      /*MyPrint.printOnConsole("value:$value, T:${T.toString()}");

      switch (T.toString()) {
        case "dynamic":
          {
            MyPrint.printOnConsole("Is dynamic");
          }
        case "String":
          {
            MyPrint.printOnConsole("Is String");
          }
        case "String?":
          {
            MyPrint.printOnConsole("Is String?");
          }
        case "int":
          {
            MyPrint.printOnConsole("Is Int");
          }
        case "int?":
          {
            MyPrint.printOnConsole("Is Int?");
          }
        case "double":
          {
            MyPrint.printOnConsole("Is Double");
          }
        case "double?":
          {
            MyPrint.printOnConsole("Is Double?");
          }
        case "bool":
          {
            MyPrint.printOnConsole("Is Bool");
          }
        case "bool?":
          {
            MyPrint.printOnConsole("Is Bool?");
          }
        case "List":
          {
            MyPrint.printOnConsole("Is List");
          }
        case "List<String>":
          {
            MyPrint.printOnConsole("Is List<String>");
          }
        case "List<int>":
          {
            MyPrint.printOnConsole("Is List<int>");
          }
        case "List<double>":
          {
            MyPrint.printOnConsole("Is List<double>");
          }
        case "List<bool>":
          {
            MyPrint.printOnConsole("Is List<bool>");
          }
        case "Map<String, dynamic>":
          {
            MyPrint.printOnConsole("Is Map<String, dynamic>");
          }
        default:
          {
            MyPrint.printOnConsole("Is Not Known");
          }
      }*/

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