import 'dart:async';
import 'dart:convert';

import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/models/user/data_model/user_model.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/shared_pref_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';


class AuthenticationRepository {
  final String baseUrl = 'https://172.86.92.130.sslip.io/api';

  Future<Map<String, dynamic>?> registerNewUserFromPayload(Map<String, dynamic> payload) async {
    try {
      final url = '$baseUrl/auth/register';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      MyPrint.printOnConsole("Register response code: ${response.statusCode}");
      MyPrint.printOnConsole("Register response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        MyPrint.printOnConsole("Registration failed: ${response.body}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("Error in registerNewUserFromPayload: $e");
      return null;
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<Map<String, dynamic>?> signInWithGoogle({required BuildContext context}) async {
    MyPrint.printOnConsole("AuthenticationRepository().signInWithGoogle() called");

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        MyPrint.printOnConsole("Google Sign In cancelled by user");
        return null;
      }

      MyPrint.printOnConsole("Google user signed in: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String accessToken = googleAuth.accessToken!;
      MyPrint.printOnConsole("Access token retrieved: $accessToken");

      MyPrint.printOnConsole("Sending access token to backend...");
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/mobile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accessToken': accessToken,
        }),
      );

      MyPrint.printOnConsole("Backend response code: ${response.statusCode}");
      MyPrint.printOnConsole("Backend response body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        MyPrint.printOnConsole("Failed to authenticate with backend");
        return null;
      }

      // Parse response from your backend
      final responseData = json.decode(response.body);
      MyPrint.printOnConsole("Decoded backend response: $responseData");

      final String? token = responseData['token'];
      if (token == null || token.isEmpty) {
        MyPrint.printOnConsole("No token received from backend");
        return null;
      }

      MyPrint.printOnConsole("Token received: $token");

      await SharedPrefManager().setString(MySharedPreferenceVariables.authToken, token);
      MyPrint.printOnConsole("Token stored in shared preferences");

      final userData = responseData['user'];
      if (userData == null) {
        MyPrint.printOnConsole("User data not in response, fetching separately");

        final userResponse = await http.get(
          Uri.parse('$baseUrl/auth/me'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        MyPrint.printOnConsole("User info response code: ${userResponse.statusCode}");
        MyPrint.printOnConsole("User info response body: ${userResponse.body}");

        if (userResponse.statusCode != 200 && userResponse.statusCode != 201) {
          MyPrint.printOnConsole("Failed to get user data");
          return null;
        }

        return {
          'token': token,
          'userData': json.decode(userResponse.body),
        };
      }

      MyPrint.printOnConsole("User data received from backend response: $userData");

      return {
        'token': token,
        'userData': userData,
      };
    } catch (e, stackTrace) {
      MyPrint.printOnConsole("Error during Google sign-in: $e");
      MyPrint.printOnConsole("StackTrace: $stackTrace");
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkEmailExists(String email) async {
    MyPrint.printOnConsole("AuthenticationRepository().checkEmailExists() called for $email");

    try {
      final encodedEmail = Uri.encodeComponent(email.toLowerCase());
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-email/$encodedEmail'),
      );

      MyPrint.printOnConsole("Email check response status: ${response.statusCode}");
      MyPrint.printOnConsole("Email check response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response which should contain isInUse and passwordSet
        final responseData = json.decode(response.body);
        return {
          'isInUse': responseData['isInUse'] ?? false,
          'passwordSet': responseData['passwordSet'] ?? false,
        };
      } else {
        MyPrint.printOnConsole("Failed to check email: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("Error checking email: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    MyPrint.printOnConsole("AuthenticationRepository().signInWithEmail() called");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      MyPrint.printOnConsole("Login response status: ${response.statusCode}");
      MyPrint.printOnConsole("Login response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userData = data['user'];

        if (token != null) {
          // Log the actual token value
          MyPrint.printOnConsole("Received authToken: $token");
          await SharedPrefManager().setString(MySharedPreferenceVariables.authToken, token);
          MyPrint.printOnConsole("Stored authToken: $token");
          return {
            'token': token,
            'userData': userData,
          };
        } else {
          MyPrint.printOnConsole("Token is null in response");
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          MyPrint.printOnConsole("Login error details: $errorData");
        } catch (e) {
          // If we can't parse the error, just log the raw response
          MyPrint.printOnConsole("Raw error response: ${response.body}");
        }
      }

      return null;
    } catch (e) {
      MyPrint.printOnConsole("Error during email sign-in: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerNewUser(UserModel userModel) async {
    try {
      MyPrint.printOnConsole("Register Request Payload: ${json.encode(userModel.toMap())}");

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userModel.toMap()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        MyPrint.printOnConsole("Registration failed with status: ${response.statusCode}");
        MyPrint.printOnConsole("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      MyPrint.printOnConsole("Error during registration: $e");
      return null;
    }
  }

  Future<bool> uploadKeyBundle({
    required String token,
    required Map<String, dynamic> keyBundle,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/keys'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(keyBundle),
      );

      MyPrint.printOnConsole(
          'Key upload response code: ${response.statusCode}');
      MyPrint.printOnConsole('Key upload response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      MyPrint.printOnConsole('Error uploading key bundle: $e');
      return false;
    }
  }

  Future<UserModel?> getUserFromToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> userData = json.decode(response.body);

        MyPrint.printOnConsole("user data from token: ${userData}");
        UserModel user = UserModel.fromMap(userData);
        MyPrint.printOnConsole("user model from get user token mapped data: ${user}");
        return user;
      }

      return null;
    } catch (e) {
      MyPrint.printOnConsole("Error fetching user data: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      MyPrint.printOnConsole("Error signing out from Google: $e");
    }
  }
}