import 'dart:convert';
import 'dart:io';

import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../authentication/auth_utils.dart';

class UserRepository {
  final String baseUrl = 'https://172.86.92.130.sslip.io/api';

  Future<bool> updateDisplayName({required String token, required String name}) async {
    final url = Uri.parse('$baseUrl/update-profile');
    try {
      final response = await http.post(url, headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({'name': name}));
      MyPrint.printOnConsole('Update profile status: ${response.statusCode}');
      if (response.statusCode == 401) {
        await AuthUtils.handleUnauthorized();
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      MyPrint.printOnConsole('Error updating profile name: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> updateProfile({required String token, String? name, File? profilePhoto}) async {
    final url = Uri.parse('$baseUrl/update-profile');
    try {
      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }

      if (profilePhoto != null) {
        MyPrint.printOnConsole('Selected image path: ${profilePhoto.path}');

        // Determine MIME type (e.g., image/jpeg)
        final mimeType = lookupMimeType(profilePhoto.path);
        MediaType? mediaType;

        if (mimeType != null) {
          final parts = mimeType.split('/');
          if (parts.length == 2) {
            mediaType = MediaType(parts[0], parts[1]);
          }
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_photo',
            profilePhoto.path,
            contentType: mediaType, // Correct MIME type
          ),
        );
      }

      // 🧾 Print full form-data fields and files before sending
      MyPrint.printOnConsole('Fields: ${request.fields}');
      MyPrint.printOnConsole('Files: ${request.files.map((f) => '${f.field} => ${f.filename} (${f.contentType})').toList()}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      MyPrint.printOnConsole('Update profile status: ${response.statusCode}');
      MyPrint.printOnConsole('Update profile response: $responseBody');

      if (response.statusCode == 401) {
        await AuthUtils.handleUnauthorized();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseBody);
      }
    } catch (e) {
      MyPrint.printOnConsole('Error updating profile: $e');
    }
    return null;
  }
}
