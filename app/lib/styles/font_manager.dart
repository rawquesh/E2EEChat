import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FontFamily {
  tiempos,
  epilogue,
  system,
}

class FontManager {
  static FontManager? _instance;
  static FontFamily _fontFamily = FontFamily.system;

  factory FontManager() {
    _instance ??= FontManager._();
    return _instance!;
  }

  FontManager._();

  static void setFontFamily(FontFamily family) {
    _fontFamily = family;
  }

  static TextStyle applyFontFamily(
    TextStyle style, {
    FontFamily? fontFamily,
    FontWeight? fontWeight,
    Color? color,
    double? fontSize,
  }) {
    final family = fontFamily ?? _fontFamily;

    switch (family) {
      case FontFamily.epilogue:
        return GoogleFonts.epilogue(
          textStyle: style,
          fontWeight: fontWeight,
          color: color,
          fontSize: fontSize,
        );
      case FontFamily.system:
      default:
        return style.copyWith(
          fontWeight: fontWeight,
          color: color,
          fontSize: fontSize,
        );
    }
  }
}

extension FontStyleExtension on TextStyle {
  TextStyle withFont(FontFamily fontFamily) {
    return FontManager.applyFontFamily(this, fontFamily: fontFamily);
  }

  TextStyle get withEpilogue => FontManager.applyFontFamily(this, fontFamily: FontFamily.epilogue);
}
