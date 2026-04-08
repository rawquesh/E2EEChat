import 'package:flutter/material.dart';
import 'package:e2ee_android_app/widgets/common_text.dart';

class CommonSubmitButton extends StatelessWidget {
  final Function onTap;
  final String text;
  final Widget? child;
  final double verticalPadding;
  final double horizontalPadding;
  final double fontSize, elevation;
  final double? height;
  final double borderRadius;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isSelected;
  final Color? fontColor;
  final FontWeight? fontWeight;
  final Color? backgroundColor;
  final BoxBorder? border;

  const CommonSubmitButton({
    super.key,
    required this.onTap,
    this.text = "",
    this.child,
    this.height,
    this.elevation = 2,
    this.verticalPadding = 13,
    this.fontSize = 16,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius = 8,
    this.horizontalPadding = 40,
    this.isSelected = true,
    this.fontColor,
    this.fontWeight,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    return InkWell(
      onTap: () {
        onTap();
      },
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
        decoration: BoxDecoration(
          color: backgroundColor ?? themeData.primaryColor,
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            prefixIcon != null
                ? Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: prefixIcon!,
            )
                : Container(),
            child != null
                ? child!
                : CommonText(
              text: text,
              color: fontColor ?? themeData.colorScheme.onPrimary,
              fontSize: fontSize,
              fontWeight: fontWeight ?? FontWeight.normal,
            ),
            suffixIcon != null
                ? Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: suffixIcon!,
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}