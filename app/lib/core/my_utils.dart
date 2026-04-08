// Merged: combines methods from both apps

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'my_http_overrides.dart';
import 'my_print.dart';
import 'my_toast.dart';

class MyUtils {
  static Future<void> copyToClipboard(BuildContext? context, String string) async {
    if (string.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: string));
      if (context != null) {
        MyToast.showSuccess(context: context, msg: "Copied");
      }
    }
  }

  static String getNewId({bool isFromUuid = true}) {
    if (isFromUuid) {
      return const Uuid().v1().replaceAll("-", "");
    } else {
      return _generateFirestoreStyleId();
    }
  }

  static String _generateFirestoreStyleId() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final Random random = Random.secure();
    return List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String encodeJson(Object? object) {
    try {
      return jsonEncode(object);
    } catch (e, s) {
      MyPrint.printOnConsole("Error in MyUtils.encodeJson():$e");
      MyPrint.printOnConsole(s);
      return "";
    }
  }

  static dynamic decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (e, s) {
      MyPrint.printOnConsole("Error in MyUtils.decodeJson():$e");
      MyPrint.printOnConsole(s);
      return null;
    }
  }

  static void hideShowKeyboard({bool isHide = true}) {
    SystemChannels.textInput.invokeMethod(isHide ? 'TextInput.hide' : 'TextInput.show');
  }

  static void initializeHttpOverrides() {
    if (!kIsWeb) {
      HttpOverrides.global = MyHttpOverrides();
      HttpClient httpClient = HttpClient();
      httpClient.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
    }
  }

  static String getSecureUrl(String url) {
    String scheme = Uri.base.scheme;

    String current = "", target = "";
    if (scheme == "http") {
      current = "https:";
      target = "http:";
    } else {
      current = "http:";
      target = "https:";
    }
    if (url.startsWith(current)) {
      url = url.replaceFirst(current, target);
    }
    return url;
  }

  static String getHostNameFromSiteUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      Uri uri = Uri.parse(url);
      return uri.host;
    }
    return "";
  }

  String getStorageUploadImageUrl({required String nativeImageName}) {
    int dotIndex = nativeImageName.lastIndexOf('.');
    String finalImageUrl = nativeImageName.substring(dotIndex);
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    return '$currentTime$finalImageUrl';
  }

  static bool isValidMobileNumber(String mobileNumber) {
    RegExp exp = RegExp(r'^(\+91|0)?[6-9]\d{9}$');
    return exp.hasMatch(mobileNumber);
  }

  static String formatDigitsForAmount({required double amount, String symbol = "₹", int? decimalDigits}) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  String formatedListDate(DateTime date) {
    String day = DateFormat('d').format(date);
    String month = DateFormat('MMM').format(date);
    String year = DateFormat('y').format(date);
    String suffix = getDaySuffix(int.parse(day));
    return "$day$suffix $month $year";
  }

  String getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  static commonShowModelBottomSheet({required Widget bodyWidget, required BuildContext context}) {
    return showModalBottomSheet<void>(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                width: 100,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              SizedBox(height: 10),
              bodyWidget,
              SizedBox(height: 60),
            ],
          ),
        );
      },
    );
  }

  static Future<String> getDocumentsDirectory() async {
    if (kIsWeb) {
      return "";
    }
    final directory = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
    return directory?.path ?? "";
  }

  static String? getPathSeparator() {
    if (kIsWeb) {
      return null;
    }
    return Platform.pathSeparator;
  }

  static String formatNumber({required double number}) {
    if (number % 1 == 0) {
      return number.toStringAsFixed(0);
    } else if (number.toStringAsFixed(2).endsWith('0')) {
      return number.toStringAsFixed(1);
    } else {
      return number.toStringAsFixed(2);
    }
  }

  static Future<String> saveFileToDevice(Uint8List fileBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);
    return filePath;
  }

  static Future<String> saveFileToVault(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final vaultDirectory = Directory('${directory.path}/vault');
    if (!await vaultDirectory.exists()) {
      await vaultDirectory.create();
    }
    final fileName = filePath.split('/').last;
    final newFilePath = '${vaultDirectory.path}/$fileName';
    final file = File(filePath);
    await file.copy(newFilePath);
    return newFilePath;
  }
}
