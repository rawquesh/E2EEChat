import 'package:flutter/material.dart';

import 'common_submit_button.dart';

class CommonConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String cancelText;
  final String confirmationText;
  final GestureTapCallback? onCancelTap, onConfirmTap;
  final bool showCancel, showConfirm;

  const CommonConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    this.cancelText = "",
    this.confirmationText = "",
    this.onCancelTap,
    this.onConfirmTap,
    this.showCancel = true,
    this.showConfirm = true,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);

    return AlertDialog(
      title: Text(
        title,
        style: themeData.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            description,
            style: themeData.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.normal,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (showCancel)
                  Flexible(
                    child: CommonSubmitButton(
                      onTap: () {
                        if (onCancelTap != null) {
                          onCancelTap!();
                        } else {
                          Navigator.of(context).pop(false);
                        }
                      },
                      backgroundColor: themeData.colorScheme.onPrimary,
                      border: Border.all(color: themeData.primaryColor),
                      fontColor: themeData.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      text: cancelText.isNotEmpty ? cancelText : "Cancel",
                      verticalPadding: 10,
                      horizontalPadding: 10,
                    ),
                  ),
                if (showConfirm)
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      child: CommonSubmitButton(
                        onTap: () {
                          if (onConfirmTap != null) {
                            onConfirmTap!();
                          } else {
                            Navigator.of(context).pop(true);
                          }
                        },
                        backgroundColor: themeData.primaryColor,
                        fontColor: themeData.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        text: confirmationText.isNotEmpty ? confirmationText : "Confirm",
                        verticalPadding: 10,
                        horizontalPadding: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}