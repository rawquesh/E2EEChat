import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'my_print.dart';

/*extension MyGeoPointExtension on GeoPoint? {
  dynamic toMap({bool toJson = false}) {
    if (toJson) {
      return getGeoPointJson();
    } else {
      return this;
    }
  }

  Map<String, dynamic>? getGeoPointJson() {
    GeoPoint? geoPoint = this;

    if (geoPoint == null) return null;

    return {
      "lat": geoPoint.latitude,
      "lon": geoPoint.longitude,
    };
  }
}*/

extension MyDateTimeExtension on DateTime {
  String? getDateString({String? defaultValue}) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(this);
    } catch (e, s) {
      MyPrint.printOnConsole("Error in Converting DateTime to String in MyDateTimeExtension().getDateString():$e");
      MyPrint.printOnConsole(s);
      return defaultValue;
    }
  }
}

extension MyStringExtension on String? {
  bool get checkNotEmpty => (this ?? '').isNotEmpty;

  bool get checkEmpty => (this ?? '').isEmpty;
}

extension MyDoubleExtension on double? {
  String? getFormattedNumber({int? precision}) {
    if (this == null) return null;

    if (precision == null) {
      String strNumber = this!.toString();
      if (strNumber.contains('.')) {
        return strNumber.replaceAll(RegExp(r"0*$"), "").replaceAll(RegExp(r"\.$"), "");
      }
      return strNumber;
    }

    String formattedNumber = this!.toStringAsFixed(precision);
    if (formattedNumber.contains('.')) {
      formattedNumber = formattedNumber.replaceAll(RegExp(r"0*$"), "").replaceAll(RegExp(r"\.$"), "");
    }
    return formattedNumber;
  }
}

extension MyMapExtension on Map? {
  bool get checkNotEmpty => (this ?? {}).isNotEmpty;

  bool get checkEmpty => (this ?? {}).isEmpty;
}

extension MyIterableExtension<T> on Iterable<T>? {
  bool get checkNotEmpty => (this ?? []).isNotEmpty;

  bool get checkEmpty => (this ?? []).isEmpty;

  T? get firstElement => checkNotEmpty ? this!.first : null;

  T? get lastElement => checkNotEmpty ? this!.last : null;

  bool checkContains(T value) => this != null ? this!.contains(value) : false;

  bool checkNotContains(T value) => !checkContains(value);

  T? elementAtIndex(int index) => this != null && index >= 0 && index < this!.length ? this!.elementAt(index) : null;
}

extension ColorFromString on String {
  Color getColor() {
    return HexColor.fromHex(this);
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    bool isValid = _isValidHexColorString(hexString);

    if (isValid) {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xff000000);
    } else {
      return const Color(0xff000000);
    }
  }

  static bool _isValidHexColorString(String color) {
    RegExp exp = RegExp(r"#?([\da-fA-F]{2})([\da-fA-F]{2})([\da-fA-F]{2})");

    return exp.hasMatch(color);
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

extension TryParseDateTime on DateFormat {
  DateTime? tryParse(String inputString, [bool utc = false]) {
    DateTime? dateTime;

    try {
      dateTime = parse(inputString, utc);
    } catch (e, s) {
      MyPrint.printOnConsole("Error in TryParseDateTime().tryParse():$e");
      MyPrint.printOnConsole(s);
    }

    return dateTime;
  }
}

extension ContextExtension on BuildContext {
  bool checkMounted() {
    try {
      return mounted;
    } catch (e, s) {
      MyPrint.printOnConsole("Error in ContextExtension.checkMounted():$e");
      MyPrint.printOnConsole(s);
      return false;
    }
  }

  Size get sizeData => MediaQuery.of(this).size;
}

mixin MyStatelessMixin on StatelessWidget {
  late ThemeData themeData;

  void pageBuild(BuildContext context) {
    themeData = Theme.of(context);
  }
}