import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyCupertinoAlertDialogWidget extends StatelessWidget {
  final String? title;
  final String? description;
  final String? positiveText;
  final String? neagtiveText;
  final Function? positiviCallback;
  final Function? negativeCallback;
  final Color? posotivetextColor;

  const MyCupertinoAlertDialogWidget({
    super.key,
    this.title,
    this.description,
    this.positiveText,
    this.positiviCallback,
    this.posotivetextColor,
    this.neagtiveText,
    this.negativeCallback,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    return CupertinoAlertDialog(
      title: Text(
        title ?? "Title",
        style: themeData.textTheme.titleMedium?.copyWith(
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Container(
        margin: const EdgeInsets.only(top: 16),
        child: Text(
          description ?? "Description",
          style: themeData.textTheme.bodyMedium?.copyWith(
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          child: Text(
            neagtiveText ?? "Cancel",
            style: themeData.textTheme.titleMedium?.copyWith(
              color: themeData.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          onPressed: () {
            if (negativeCallback != null) {
              negativeCallback!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        CupertinoDialogAction(
          child: Text(
            positiveText ?? "Ok",
            style: themeData.textTheme.titleMedium?.copyWith(
              color: posotivetextColor ?? themeData.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          onPressed: () {
            if (positiviCallback != null) {
              positiviCallback!();
            }
          },
        ),
      ],
    );
  }
}
