class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;
  final String? endpoint;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
    this.endpoint,
  });

  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500 && statusCode < 600;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isNetworkError => statusCode == 0;

  factory ApiException.networkError({String? endpoint}) {
    return ApiException(
      statusCode: 0,
      message: 'Network error. Please check your connection.',
      endpoint: endpoint,
    );
  }

  factory ApiException.timeout({String? endpoint}) {
    return ApiException(
      statusCode: 0,
      message: 'Request timed out.',
      endpoint: endpoint,
    );
  }

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}
