import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../managers/shared_pref_manager.dart';
import '../../constants/app_constants.dart';
import '../../utils/my_print.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'api_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => ApiEndpoints.baseUrl;

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth) {
      final token = await SharedPrefManager().getString(MySharedPreferenceVariables.authToken);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    final tag = DateTime.now().millisecondsSinceEpoch.toString();
    MyPrint.printOnConsole("GET: $endpoint [Tag: $tag]", tag: tag);

    try {
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      final headers = customHeaders ?? await _getHeaders(includeAuth: includeAuth);
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout(endpoint: endpoint),
      );

      return _parseResponse(response, tag);
    } on ApiException {
      rethrow;
    } catch (e) {
      MyPrint.printOnConsole("Exception GET $endpoint: $e [Tag: $tag]", tag: tag);
      return ApiResponse.error(
        statusCode: 0,
        errorMessage: e.toString(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    final tag = DateTime.now().millisecondsSinceEpoch.toString();
    MyPrint.printOnConsole("POST: $endpoint [Tag: $tag]", tag: tag);

    try {
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      final headers = customHeaders ?? await _getHeaders(includeAuth: includeAuth);
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout(endpoint: endpoint),
      );

      return _parseResponse(response, tag);
    } on ApiException {
      rethrow;
    } catch (e) {
      MyPrint.printOnConsole("Exception POST $endpoint: $e [Tag: $tag]", tag: tag);
      return ApiResponse.error(
        statusCode: 0,
        errorMessage: e.toString(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    final tag = DateTime.now().millisecondsSinceEpoch.toString();
    MyPrint.printOnConsole("PUT: $endpoint [Tag: $tag]", tag: tag);

    try {
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      final headers = customHeaders ?? await _getHeaders(includeAuth: includeAuth);
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout(endpoint: endpoint),
      );

      return _parseResponse(response, tag);
    } on ApiException {
      rethrow;
    } catch (e) {
      MyPrint.printOnConsole("Exception PUT $endpoint: $e [Tag: $tag]", tag: tag);
      return ApiResponse.error(
        statusCode: 0,
        errorMessage: e.toString(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
    Map<String, String>? customHeaders,
  }) async {
    final tag = DateTime.now().millisecondsSinceEpoch.toString();
    MyPrint.printOnConsole("DELETE: $endpoint [Tag: $tag]", tag: tag);

    try {
      final uri = Uri.parse(baseUrl + endpoint).replace(queryParameters: queryParams);
      final headers = customHeaders ?? await _getHeaders(includeAuth: includeAuth);
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw ApiException.timeout(endpoint: endpoint),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response, tag);
    } on ApiException {
      rethrow;
    } catch (e) {
      MyPrint.printOnConsole("Exception DELETE $endpoint: $e [Tag: $tag]", tag: tag);
      return ApiResponse.error(
        statusCode: 0,
        errorMessage: e.toString(),
      );
    }
  }

  // --- Throwing variants ---
  Future<Map<String, dynamic>> getOrThrow(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    final response = await get(endpoint, queryParams: queryParams, includeAuth: includeAuth);
    if (!response.success) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.errorMessage ?? 'Request failed',
        endpoint: endpoint,
      );
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> postOrThrow(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    final response = await post(endpoint, body: body, queryParams: queryParams, includeAuth: includeAuth);
    if (!response.success) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.errorMessage ?? 'Request failed',
        endpoint: endpoint,
      );
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> putOrThrow(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    final response = await put(endpoint, body: body, queryParams: queryParams, includeAuth: includeAuth);
    if (!response.success) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.errorMessage ?? 'Request failed',
        endpoint: endpoint,
      );
    }
    return response.data!;
  }

  Future<Map<String, dynamic>> deleteOrThrow(
    String endpoint, {
    Object? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    final response = await delete(endpoint, body: body, queryParams: queryParams, includeAuth: includeAuth);
    if (!response.success) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.errorMessage ?? 'Request failed',
        endpoint: endpoint,
      );
    }
    return response.data!;
  }

  ApiResponse<Map<String, dynamic>> _parseResponse(http.Response response, String tag) {
    MyPrint.printOnConsole("Response [${response.statusCode}]: ${response.body} [Tag: $tag]", tag: tag);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return ApiResponse.success(
          data: data is Map<String, dynamic> ? data : {'data': data},
          statusCode: response.statusCode,
        );
      } catch (e) {
        return ApiResponse.error(
          statusCode: response.statusCode,
          errorMessage: 'Failed to parse response',
        );
      }
    } else {
      String errorMessage = 'Request failed with status ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          errorMessage = body['message'];
        }
      } catch (_) {}
      return ApiResponse.error(
        statusCode: response.statusCode,
        errorMessage: errorMessage,
      );
    }
  }
}
