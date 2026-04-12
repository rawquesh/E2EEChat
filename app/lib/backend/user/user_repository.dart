import 'dart:convert';
import 'dart:io';

import 'package:e2ee_android_app/utils/my_print.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../authentication/auth_utils.dart';
import '../common/api_endpoints.dart';

class UserRepository {
  Future<bool> updateDisplayName({required String token, required String name}) async {
    final url = Uri.parse(ApiEndpoints.urlUpdateProfile);
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

  Future<Map<String, dynamic>?> updateProfile({
    required String token,
    String? name,
    File? profilePhoto
  }) async {
    final url = Uri.parse(ApiEndpoints.urlUpdateProfile);

    try {
      MyPrint.printOnConsole('Starting profile update - Name: $name, Photo: ${profilePhoto?.path}');

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      // Debug print for headers
      MyPrint.printOnConsole('Request Headers: ${request.headers}');

      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
        MyPrint.printOnConsole('Added name field: $name');
      }

      if (profilePhoto != null) {
        MyPrint.printOnConsole('Adding profile photo from path: ${profilePhoto.path}');
        request.files.add(await http.MultipartFile.fromPath(
          'profile_photo',
          profilePhoto.path,
          contentType: MediaType('image', 'jpeg'), // Or png
        ));
        MyPrint.printOnConsole('Profile photo added successfully');
      }

      // Debug print for request fields/files before sending
      MyPrint.printOnConsole('Request Fields: ${request.fields}');
      // MyPrint.printOnConsole('Request Files: ${request.files.map((f) => f.field + ': ' + f.filename).toList()}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Enhanced debug prints
      MyPrint.printOnConsole('Update profile status: ${response.statusCode}');
      MyPrint.printOnConsole('Update profile headers: ${response.headers}');
      MyPrint.printOnConsole('Update profile response body: $responseBody');
      MyPrint.printOnConsole('Response content length: ${response.contentLength} bytes');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(responseBody);
        MyPrint.printOnConsole('Profile update successful: ${jsonResponse.containsKey('success')}');
        return jsonResponse;
      } else {
        MyPrint.printOnConsole('Profile update failed with status: ${response.statusCode}');
        // Debug print for error response if available
        try {
          final errorResponse = json.decode(responseBody);
          MyPrint.printOnConsole('Error details: $errorResponse');
        } catch (e) {
          MyPrint.printOnConsole('Non-JSON error response: $responseBody');
        }
      }
    } catch (e, stackTrace) {
      MyPrint.printOnConsole('Error updating profile: $e');
      MyPrint.printOnConsole('Stack trace: $stackTrace');
      if (e is SocketException) {
        MyPrint.printOnConsole('Network error: ${e.message}');
      }
    }

    return null;
  }
}
