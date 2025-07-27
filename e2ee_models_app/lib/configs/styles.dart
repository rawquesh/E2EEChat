import 'package:flutter/material.dart';

// import 'package:flutter/material.dart';

// import 'package:flutter/material.dart';

class Styles {
  static final Styles _instance = Styles._();

  Styles._();

  factory Styles() => _instance;

  static const Color yellow50 = Color(0xFFFFFDE7);  // very light
  static const Color yellow100 = Color(0xFFFFF9C4); // light yellow
  static const Color yellow200 = Color(0xFFFFF59D); // soft warm
  static const Color yellow300 = Color(0xFFFFF176); // mild highlight
  static const Color yellow400 = Color(0xFFFFEE58); // primary action yellow
  static const Color yellow500 = Color(0xFFFFEB3B); // main button yellow
  static const Color yellow600 = Color(0xFFFDD835); // hover
  static const Color yellow700 = Color(0xFFFBC02D); // pressed
  static const Color yellow800 = Color(0xFFF9A825); // accent
  static const Color yellow900 = Color(0xFFF57F17); // deep warning yellow

  // Light and Dark Themes
  Color lightPrimaryColor = yellow700;
  Color darkPrimaryColor = yellow800;

  Color lightPrimaryVariant = yellow300;
  Color darkPrimaryVariant = yellow800;

  Color lightSecondaryColor = yellow400;
  Color darkSecondaryColor = yellow600;

  Color lightSecondaryVariant = yellow300;
  Color darkSecondaryVariant = yellow800;

  Color darkTertiaryColor = yellow400;
  Color darkTertiaryContainerColor = yellow700;

  Color lightAppBarTextColor = const Color(0xFF000000); // dark text
  Color darkAppBarTextColor = const Color(0xFFFFFFFF); // light text

  Color lightTextColor = const Color(0xFF000000); // black text
  Color darkTextColor = const Color(0xFFFFFFFF); // white text

  Color lightBackgroundColor = Colors.white;
  Color darkBackgroundColor = const Color(0xFF121212); // dark base

  Color lightAppBarColor = Colors.white;
  Color darkAppBarColor = const Color(0xFF121212); // deep blue

  Color lightTextFiledFillColor = Colors.white;
  Color darkTextFiledFillColor = const Color(0xFF1E1E1E);

  Color lightHoverColor = yellow500.withOpacity(0.2);
  Color darkHoverColor = Colors.grey.withOpacity(0.5);

  Color lightFocusedTextFormFieldColor = yellow400.withOpacity(0.3);
  Color darkFocusedTextFormFieldColor = yellow500.withOpacity(0.5);

  // Gradients
  static const LinearGradient gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [yellow500, yellow800],
  );

  // Common UI Elements
  Color cardColor = Colors.white;
  Color myPrimaryColor = yellow800;
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

  // Shimmer Colors
  static Color shimmerHighlightColor = const Color(0xFFF2F2F2);
  static Color shimmerBaseColor = const Color(0xFFB6B6B6);
  static Color shimmerContainerColor = const Color(0xFFC2C2C2);

  // Button Styling
  double buttonBorderRadius = 5;
}

