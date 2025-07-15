import 'package:encrypt/encrypt.dart' as encrypt;

import 'my_print.dart';
import 'parsing_helper.dart';

class EncryptionHelper {
  late final String _encryptionKey;

  EncryptionHelper({required String encryptionKey}) {
    _encryptionKey = encryptionKey;
  }

  String get encryptionKey => _encryptionKey;

  //region Encryption
  Map<String, dynamic> encryptMap({required Map<String, dynamic> map}) {
    if (encryptionKey.isEmpty) {
      return map;
    }

    Map<String, dynamic> encryptedMap = {};

    try {
      map.forEach((String key, dynamic value) {
        String encryptedKey = encryptString(text: key);

        if (encryptedKey.isNotEmpty) {
          dynamic encryptedValue = encryptDynamicValue(value: value);

          encryptedMap[encryptedKey] = encryptedValue;
        }
      });
    } catch (e, s) {
      MyPrint.printOnConsole("Error in EncryptionHelper.encryptMap():$e");
      MyPrint.printOnConsole(s);
    }

    // print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
    // print(encrypted.base64); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==

    return encryptedMap.isNotEmpty ? encryptedMap : map;
  }

  dynamic encryptDynamicValue({required dynamic value}) {
    if (encryptionKey.isEmpty) {
      return value;
    }

    if (value is List) {
      return value.map((e) => encryptDynamicValue(value: e)).toList();
    } else if (value is Map) {
      return value.map((dynamic key, dynamic value) {
        return MapEntry(
          encryptDynamicValue(value: key),
          encryptDynamicValue(value: value),
        );
      });
    } else {
      String stringValue = ParsingHelper.parseStringMethod(value);
      return encryptString(text: stringValue);
    }
  }

  String encryptString({required String text}) {
    if (encryptionKey.isEmpty || text.isEmpty) {
      return text;
    }

    String encryptedText = "";

    try {
      final key = encrypt.Key.fromUtf8(encryptionKey);
      final iv = encrypt.IV.fromLength(16);

      final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(
        key,
        mode: encrypt.AESMode.ecb,
      ));

      // encryptedText = encrypter.encrypt(text, iv: iv).base64;
      encryptedText = encrypter.encrypt(text, iv: iv).base64;
    } catch (e, s) {
      MyPrint.printOnConsole("Error in EncryptionHelper.encryptString():$e");
      MyPrint.printOnConsole(s);
    }

    // print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
    // print(encrypted.base64); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==

    return encryptedText;
  }

  //endregion

  //region Decryption
  Map<String, dynamic> decryptMap({required Map<String, dynamic> map}) {
    if (encryptionKey.isEmpty) {
      return map;
    }

    Map<String, dynamic> decryptedMap = {};

    try {
      map.forEach((String key, dynamic value) {
        String decryptedKey = decryptString(encryptedText: key);

        if (decryptedKey.isNotEmpty) {
          dynamic decryptedValue = decryptDynamicValue(value: value);

          decryptedMap[decryptedKey] = decryptedValue;
        }
      });
    } catch (e, s) {
      MyPrint.printOnConsole("Error in EncryptionHelper.decryptMap():$e");
      MyPrint.printOnConsole(s);
    }

    // print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
    // print(encrypted.base64); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==

    return decryptedMap.isNotEmpty ? decryptedMap : map;
  }

  dynamic decryptDynamicValue({required dynamic value}) {
    if (encryptionKey.isEmpty) {
      return value;
    }

    if (value is List) {
      return value.map((e) => decryptDynamicValue(value: e)).toList();
    } else if (value is Map) {
      return value.map((dynamic key, dynamic value) {
        return MapEntry(
          decryptDynamicValue(value: key),
          decryptDynamicValue(value: value),
        );
      });
    } else {
      String stringValue = ParsingHelper.parseStringMethod(value);
      return decryptString(encryptedText: stringValue);
    }
  }

  String decryptString({required String encryptedText}) {
    if (encryptionKey.isEmpty || encryptedText.isEmpty) {
      return encryptedText;
    }

    String decryptedText = encryptedText;

    try {
      final key = encrypt.Key.fromUtf8(encryptionKey);
      final iv = encrypt.IV.fromLength(16);

      final encrypt.Encrypter encrypter = encrypt.Encrypter(encrypt.AES(
        key,
        mode: encrypt.AESMode.ecb,
      ));

      decryptedText = encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedText), iv: iv);
      // decryptedText = encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedText), iv: iv);
    } catch (e, s) {
      MyPrint.printOnConsole("Error in EncryptionHelper.decryptString() for encryptedText:'$encryptedText':$e");
      MyPrint.printOnConsole(s);
    }

    // print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
    // print(encrypted.base64); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==

    return decryptedText;
  }
//endregion
}
