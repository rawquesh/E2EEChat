import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../configs/constants.dart';
import '../../core/my_print.dart';
import '../../models/user/user_model.dart';
import '../../models/user/profile_update_request_model.dart';

class UserRepository {
  Future<UserModel?> updateUserProfileFromModel({
    required String? token,
    required ProfileUpdateRequestModel data,
  }) async {
    final url = Uri.parse('${ApiUrls.prodBaseUrl}/users/profile');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data.toMap()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = json.decode(response.body);
        return UserModel(
          userId: userData["_id"] ?? "",
          firstName: userData["firstName"] ?? "",
          lastName: userData["lastName"] ?? "",
          displayName: userData['displayName'],
          email: userData["email"] ?? "",
          authenticationMode: "email",
        );
      } else {
        MyPrint.printOnConsole("Failed to update profile: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("Error updating profile: $e");
      return null;
    }
  }

  Future<String?> uploadProfilePhoto({
    required String? token,
    required File imageFile,
  }) async {
    final url = Uri.parse('${ApiUrls.prodBaseUrl}/users/profile/photo');
    MyPrint.printOnConsole('Upload Profile Photo: URL = $url');

    try {
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'photo',
        fileStream,
        fileLength,
        filename: 'profile_photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final photoUrl = responseData['profilePicture'] ?? '';
        return photoUrl;
      } else {
        MyPrint.printOnConsole("Failed to upload profile photo: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("Error uploading profile photo: $e");
      return null;
    }
  }

  Future<String?> uploadProfileCover({
    required String? token,
    required File imageFile,
  }) async {
    final url = Uri.parse('${ApiUrls.prodBaseUrl}/users/profile/cover');

    try {
      final request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'cover',
        fileStream,
        fileLength,
        filename: 'cover_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['profileCover'] ?? '';
      } else {
        MyPrint.printOnConsole("Failed to upload profile cover: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("Error uploading profile cover: $e");
      return null;
    }
  }

  Future<UserModel?> updateCreatorHeadline({
    required String? token,
    required String headline,
  }) async {
    final url = Uri.parse('${ApiUrls.prodBaseUrl}/users/creator/headline');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'headline': headline}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = json.decode(response.body);
        return UserModel.fromMap(userData);
      } else {
        MyPrint.printOnConsole("Failed to update headline: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("Error updating headline: $e");
      return null;
    }
  }

  Future<UserModel?> onboardCreator({
    required String token,
    required String username,
    required String contentVisibleTo,
    required String category,
  }) async {
    final url = Uri.parse('${ApiUrls.prodBaseUrl}/users/onboard-creator');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'contentVisibleTo': contentVisibleTo,
          'category': category,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> userData = json.decode(response.body);
        MyPrint.printOnConsole("Creator onboarded successfully: ${userData['username']}");
        return UserModel.fromMap(userData);
      } else {
        MyPrint.printOnConsole('Failed to onboard creator: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole('Error onboarding creator: $e');
      return null;
    }
  }
}
