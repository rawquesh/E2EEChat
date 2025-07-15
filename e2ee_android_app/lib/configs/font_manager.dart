import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FontType {
  asset,
  google
}

class FontFamily {
  final String name;
  final FontType type;

  const FontFamily(this.name, this.type);

  // Predefined font families
  static const FontFamily tiempos = FontFamily('TestTiemposHeadline', FontType.asset);
  static const FontFamily epilogue = FontFamily('Epilogue', FontType.google);
}

class FontManager {
  static FontFamily defaultFontFamily = FontFamily.tiempos;

  static TextStyle applyFontFamily(TextStyle textStyle, {FontFamily? fontFamily}) {
    final family = fontFamily ?? defaultFontFamily;

    if (family.type == FontType.google) {
      return GoogleFonts.getFont(
        family.name,
        textStyle: textStyle,
      );
    } else {
      return textStyle.copyWith(fontFamily: family.name);
    }
  }

  static void setDefaultFont(FontFamily fontFamily) {
    defaultFontFamily = fontFamily;
  }
}

extension FontStyleExtension on TextStyle {
  TextStyle withFont(FontFamily fontFamily) {
    return FontManager.applyFontFamily(this, fontFamily: fontFamily);
  }

  TextStyle get withTiempos => FontManager.applyFontFamily(this, fontFamily: FontFamily.tiempos);
  TextStyle get withEpilogue => FontManager.applyFontFamily(this, fontFamily: FontFamily.epilogue);
}