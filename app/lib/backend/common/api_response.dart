class ApiResponse<T> {
  final bool success;
  final T? data;
  final int statusCode;
  final String? message;
  final String? errorMessage;

  factory ApiResponse.success({
    required T data,
    required int statusCode,
    String? message,
  }) {
    return ApiResponse._(
      success: true,
      data: data,
      statusCode: statusCode,
      message: message,
    );
  }

  factory ApiResponse.error({
    required int statusCode,
    required String errorMessage,
    T? data,
  }) {
    return ApiResponse._(
      success: false,
      data: data,
      statusCode: statusCode,
      errorMessage: errorMessage,
    );
  }

  ApiResponse._({
    required this.success,
    this.data,
    required this.statusCode,
    this.message,
    this.errorMessage,
  });

  bool get hasData => data != null;

  T get dataOrThrow {
    if (data == null) {
      throw Exception(errorMessage ?? 'No data available');
    }
    return data as T;
  }

  T dataOr(T fallback) => data != null ? data as T : fallback;
}
