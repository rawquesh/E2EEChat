import 'package:e2ee_models_app/configs/styles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'font_manager.dart';

class AppTheme {
  final Styles styles;
  final FontFamily fontFamily;

  const AppTheme({
    required this.styles,
    this.fontFamily = FontFamily.tiempos,
  });


  TextTheme getTextTheme({required Color color, FontFamily? overrideFontFamily}) {
    final finalFontFamily = overrideFontFamily ?? fontFamily;

    return TextTheme(
      displayLarge: FontManager.applyFontFamily(TextStyle(fontSize: 102, color: color), fontFamily: finalFontFamily),
      displayMedium: FontManager.applyFontFamily(TextStyle(fontSize: 64, color: color), fontFamily: finalFontFamily),
      displaySmall: FontManager.applyFontFamily(TextStyle(fontSize: 51, color: color), fontFamily: finalFontFamily),
      headlineLarge: FontManager.applyFontFamily(TextStyle(fontSize: 43, color: color), fontFamily: finalFontFamily),
      headlineMedium: FontManager.applyFontFamily(TextStyle(fontSize: 36, color: color), fontFamily: finalFontFamily),
      headlineSmall: FontManager.applyFontFamily(TextStyle(fontSize: 25, color: color), fontFamily: finalFontFamily),
      titleLarge: FontManager.applyFontFamily(TextStyle(fontSize: 18, color: color), fontFamily: finalFontFamily),
      titleMedium: FontManager.applyFontFamily(TextStyle(fontSize: 17, color: color), fontFamily: finalFontFamily),
      titleSmall: FontManager.applyFontFamily(TextStyle(fontSize: 15, color: color), fontFamily: finalFontFamily),
      bodyLarge: FontManager.applyFontFamily(TextStyle(fontSize: 16, color: color), fontFamily: finalFontFamily),
      bodyMedium: FontManager.applyFontFamily(TextStyle(fontSize: 14, color: color), fontFamily: finalFontFamily),
      bodySmall: FontManager.applyFontFamily(TextStyle(fontSize: 12, color: color), fontFamily: finalFontFamily),
      labelLarge: FontManager.applyFontFamily(TextStyle(fontSize: 15, color: color), fontFamily: finalFontFamily),
      labelMedium: FontManager.applyFontFamily(TextStyle(fontSize: 13, color: color), fontFamily: finalFontFamily),
      labelSmall: FontManager.applyFontFamily(TextStyle(fontSize: 11, color: color, letterSpacing: 0), fontFamily: finalFontFamily),
    );
  }

  //region App Bar Text
  TextTheme getLightAppBarTextTheme({FontFamily? overrideFontFamily}) {
    Color color = styles.lightAppBarTextColor;
    return getTextTheme(color: color, overrideFontFamily: overrideFontFamily);
  }

  TextTheme getDarkAppBarTextTheme({FontFamily? overrideFontFamily}) {
    Color color = styles.darkAppBarTextColor;
    return getTextTheme(color: color, overrideFontFamily: overrideFontFamily);
  }

  TextTheme getLightTextTheme({FontFamily? overrideFontFamily}) {
    Color color = styles.lightTextColor;
    return getTextTheme(color: color, overrideFontFamily: overrideFontFamily);
  }

  TextTheme getDarkTextTheme({FontFamily? overrideFontFamily}) {
    Color color = styles.darkTextColor;
    return getTextTheme(color: color, overrideFontFamily: overrideFontFamily);
  }

  //endregion

  //region Color Themes
  ThemeData getLightTheme() {
    Color appBarTextColor = styles.lightAppBarTextColor;
    TextTheme lightAppBarTextTheme = getTextTheme(color: appBarTextColor);

    TextTheme lightTextTheme = getLightTextTheme();

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: styles.lightPrimaryColor,
      canvasColor: styles.lightBackgroundColor,
      scaffoldBackgroundColor: styles.lightBackgroundColor,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        titleTextStyle: lightAppBarTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        toolbarTextStyle: lightAppBarTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        actionsIconTheme: IconThemeData(
          color: appBarTextColor,
        ),
        color: styles.lightAppBarColor,
        iconTheme: IconThemeData(color: appBarTextColor, size: 24),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: styles.lightPrimaryColor,
        ),
      ),
      buttonTheme:
          ButtonThemeData(buttonColor: styles.lightPrimaryColor, textTheme: ButtonTextTheme.normal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(styles.buttonBorderRadius))),
      dialogBackgroundColor: styles.lightBackgroundColor,
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: styles.lightPrimaryColor, opacity: 1, size: 24),
        unselectedIconTheme: IconThemeData(color: styles.lightTextColor, opacity: 1, size: 24),
        backgroundColor: styles.lightBackgroundColor,
        elevation: 3,
        selectedLabelTextStyle: TextStyle(color: styles.lightPrimaryColor),
        unselectedLabelTextStyle: TextStyle(color: styles.lightTextColor),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        elevation: 1,
        margin: const EdgeInsets.all(0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(fontSize: 15, color: Color(0xaa495057)),
        labelStyle: lightTextTheme.bodyMedium,
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: styles.lightPrimaryColor),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.black54),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(width: 1, color: Colors.black54),
        ),
      ),
      splashColor: Colors.white.withAlpha(100),
      iconTheme: const IconThemeData(
        color: Colors.black,
        size: 26,
      ),
      textTheme: lightTextTheme,
      indicatorColor: Colors.white,
      disabledColor: const Color(0xffdcc7ff),
      highlightColor: Colors.white,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: styles.lightPrimaryColor,
          splashColor: Colors.white.withAlpha(100),
          highlightElevation: 8,
          elevation: 4,
          focusColor: styles.lightPrimaryColor,
          hoverColor: styles.lightPrimaryColor,
          foregroundColor: Colors.white),
      dividerColor: const Color(0xffd1d1d1),
      cardColor: Colors.white,
      popupMenuTheme: PopupMenuThemeData(
        color: styles.lightBackgroundColor,
        textStyle: lightTextTheme.bodyMedium?.merge(TextStyle(color: styles.lightTextColor)),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(color: styles.lightBackgroundColor, elevation: 2),
      tabBarTheme: TabBarThemeData(
        unselectedLabelColor: styles.lightTextColor,
        labelColor: styles.lightPrimaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: styles.lightPrimaryColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: styles.lightPrimaryColor, width: 2.0),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: styles.lightPrimaryColor,
        inactiveTrackColor: styles.lightPrimaryColor.withAlpha(140),
        trackShape: const RoundedRectSliderTrackShape(),
        trackHeight: 4.0,
        thumbColor: styles.lightPrimaryColor,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
        tickMarkShape: const RoundSliderTickMarkShape(),
        inactiveTickMarkColor: Colors.red[100],
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: styles.lightBackgroundColor,
      ),
      colorScheme: ColorScheme.light(
        primary: styles.lightPrimaryColor,
        onPrimary: Colors.white,
        primaryContainer: styles.lightPrimaryVariant,
        secondary: styles.lightSecondaryColor,
        secondaryContainer: styles.lightSecondaryVariant,
        onSecondary: Colors.white,
        surface: const Color(0xffe2e7f1),
        onSurface: styles.lightTextColor,
      ).copyWith(surface: Colors.white).copyWith(error: const Color(0xfff0323c)),
    );
  }

  ThemeData getDarkTheme() {
    Color appBarTextColor = styles.darkAppBarTextColor;
    TextTheme lightAppBarTextTheme = getTextTheme(color: appBarTextColor);

    TextTheme darkTextTheme = getDarkTextTheme();

    return ThemeData(
        brightness: Brightness.dark,
        canvasColor: styles.darkBackgroundColor,
        primaryColor: styles.darkPrimaryColor,
        scaffoldBackgroundColor: styles.darkBackgroundColor,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: lightAppBarTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          toolbarTextStyle: lightAppBarTextTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
          actionsIconTheme: IconThemeData(
            color: appBarTextColor,
          ),
          color: styles.darkAppBarColor,
          iconTheme: IconThemeData(color: appBarTextColor, size: 24),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: styles.darkPrimaryColor,
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: styles.darkPrimaryColor,
          textTheme: ButtonTextTheme.primary,
        ),
        dialogBackgroundColor: styles.darkBackgroundColor,
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        navigationRailTheme: NavigationRailThemeData(
          selectedIconTheme: IconThemeData(color: styles.darkPrimaryColor, opacity: 1, size: 24),
          unselectedIconTheme: IconThemeData(color: styles.darkTextColor, opacity: 1, size: 24),
          backgroundColor: styles.darkBackgroundColor,
          elevation: 3,
          selectedLabelTextStyle: TextStyle(color: styles.darkPrimaryColor),
          unselectedLabelTextStyle: TextStyle(color: styles.darkTextColor),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xff37404a),
          shadowColor: Color(0xff000000),
          elevation: 1,
          margin: EdgeInsets.all(0),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        textTheme: darkTextTheme,
        indicatorColor: Colors.white,
        disabledColor: const Color(0xffa3a3a3),
        // highlightColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: darkTextTheme.titleMedium,
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1, color: Color(0xff10bbf0)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(width: 1, color: Colors.white70),
          ),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4)), borderSide: BorderSide(width: 1, color: Colors.white70)),
        ),
        dividerColor: const Color(0xffd1d1d1),
        cardColor: const Color(0xff282a2b),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.grey.withValues(alpha: 0.04),
        focusColor: Colors.grey.withValues(alpha: 0.16),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: styles.darkPrimaryColor,
          splashColor: Colors.transparent,
          highlightElevation: 8,
          elevation: 4,
          focusColor: styles.darkPrimaryColor,
          hoverColor: styles.darkPrimaryColor,
          foregroundColor: Colors.white,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xff37404a),
          textStyle: darkTextTheme.bodyMedium?.merge(TextStyle(color: styles.darkTextColor)),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(color: Color(0xff292929), elevation: 2),
        tabBarTheme: TabBarThemeData(
          unselectedLabelColor: styles.lightTextColor,
          labelColor: const Color(0xff10bbf0),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorColor: const Color(0xff10bbf0),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(color: Color(0xff10bbf0), width: 2.0),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xff10bbf0),
          inactiveTrackColor: styles.darkPrimaryColor.withAlpha(100),
          trackShape: const RoundedRectSliderTrackShape(),
          trackHeight: 4.0,
          thumbColor: const Color(0xff10bbf0),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
          tickMarkShape: const RoundSliderTickMarkShape(),
          inactiveTickMarkColor: Colors.red[100],
          valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
          valueIndicatorTextStyle: const TextStyle(
            color: Colors.white,
          ),
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(),
        colorScheme: ColorScheme.dark(
          primary: styles.darkPrimaryColor,
          primaryContainer: styles.darkPrimaryVariant,
          secondary: styles.darkSecondaryColor,
          secondaryContainer: styles.darkSecondaryVariant,
          tertiary: styles.darkTertiaryColor,
          tertiaryContainer: styles.darkTertiaryContainerColor,
          surface: Colors.black,
          onPrimary: Colors.white,
          onSurface: Colors.white,
          onSecondary: Colors.white,
          // surfaceContainerHighest: Color(0xff09376C),
        ).copyWith(surface: Colors.black).copyWith(error: Styles.grey500));
  }

  //endregion

  ThemeData getThemeFromThemeMode(bool isDarkThemeEnabled) {
    if (isDarkThemeEnabled) {
      return getDarkTheme();
    } else {
      return getLightTheme();
    }
  }
}
