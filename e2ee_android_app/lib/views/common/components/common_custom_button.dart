import 'package:flutter/material.dart';

class CommonCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final double? borderRadius;
  final double? fontSize;
  final Color? borderColor;
  final double? borderWidth;
  final Color? backgroundColor;
  final Color? textColor;

  const CommonCustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = 125,
    this.height = 35,
    this.fontSize = 15,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius = 10,
    this.borderColor = Colors.white,
    this.borderWidth = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? themeData.primaryColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 0),
            side: BorderSide(
              color: borderColor ?? Colors.black,
              width: borderWidth ?? 2.0,
            ),
          ),
          padding: EdgeInsets.zero,
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
