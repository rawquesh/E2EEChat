import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class MyUtils {
  static Future<String> saveFileToDevice(Uint8List fileBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(fileBytes);
    return file.path;
  }
}
