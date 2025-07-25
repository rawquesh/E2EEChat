import 'dart:convert';

import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:http/http.dart' as http;

class UserRepository {
  final String baseUrl = 'https://172.86.92.130.sslip.io/api';

  Future<bool> updateDisplayName({
    required String token,
    required String name,
  }) async {
    final url = Uri.parse('$baseUrl/update-profile');
    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name}),
      );
      MyPrint.printOnConsole('Update profile status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      MyPrint.printOnConsole('Error updating profile name: $e');
    }
    return false;
  }
}
