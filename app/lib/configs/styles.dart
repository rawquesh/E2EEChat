import 'package:flutter/material.dart';

class Styles {
  static final Styles _instance = Styles._();

  Styles._();

  factory Styles() => _instance;

  static const Color grey50 = Color.fromARGB(255, 207, 207, 207);
  static const Color grey100 = Color.fromARGB(255, 189, 189, 189);
  static const Color grey200 = Color.fromARGB(255, 165, 165, 165);
  static const Color grey300 = Color.fromARGB(255, 168, 168, 168);
  static const Color grey400 = Color.fromARGB(255, 173, 173, 173);
  static const Color grey500 = Color.fromARGB(255, 168, 168, 168);
  static const Color grey600 = Color.fromARGB(255, 167, 167, 167);
  static const Color grey700 = Color(0xff808080);
  static const Color grey800 = Color(0xff808080);
  static const Color grey900 = Color.fromARGB(255, 136, 136, 136);

  Color lightPrimaryColor = grey700;
  Color darkPrimaryColor = grey800;
  Color lightPrimaryVariant = grey300;
  Color darkPrimaryVariant = grey800;
  Color lightSecondaryColor = grey400;
  Color darkSecondaryColor = grey600;
  Color lightSecondaryVariant = grey300;
  Color darkSecondaryVariant = grey800;
  Color darkTertiaryColor = grey400;
  Color darkTertiaryContainerColor = grey700;
  Color lightAppBarTextColor = const Color(0xFF000000);
  Color darkAppBarTextColor = const Color(0xFFFFFFFF);
  Color lightTextColor = const Color(0xFF000000);
  Color darkTextColor = const Color(0xFFFFFFFF);
  Color lightBackgroundColor = Colors.white;
  Color darkBackgroundColor = const Color(0xFF121212);
  Color lightAppBarColor = Colors.white;
  Color darkAppBarColor = const Color(0xFF121212);
  Color lightTextFiledFillColor = Colors.white;
  Color darkTextFiledFillColor = const Color(0xFF1E1E1E);
  Color lightHoverColor = grey500.withOpacity(0.2);
  Color darkHoverColor = Colors.grey.withOpacity(0.5);
  Color lightFocusedTextFormFieldColor = grey400.withOpacity(0.3);
  Color darkFocusedTextFormFieldColor = grey500.withOpacity(0.5);

  static const LinearGradient gradientBackground = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [grey500, grey800]);

  Color cardColor = Colors.white;
  Color myPrimaryColor = grey800;
  Color textGrey = const Color(0xFF676767);

  static const Color scaffoldBackground = Color(0xFF212121);
  static const Color bgColor = Color(0xFFF8F8F8);
  static const Color bgSideMenu = Color(0xFF131E29);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color red = Colors.red;

  static Color greyLine = const Color(0xFFD2D2D2);
  static Color greyShade = const Color(0xFFF3F1F1);
  static Color greyShade100 = Colors.grey.shade100;

  static Color shimmerHighlightColor = const Color(0xFFF2F2F2);
  static Color shimmerBaseColor = const Color(0xFFB6B6B6);
  static Color shimmerContainerColor = const Color(0xFFC2C2C2);

  double buttonBorderRadius = 5;
}
