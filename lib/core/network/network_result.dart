import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

enum ApiStatus { loading, success, error, idle }

class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? error;
  final int? statusCode;
  
  const ApiResponse._({
    required this.status,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, [int? statusCode]) => ApiResponse._(
    status: ApiStatus.success,
    data: data,
    statusCode: statusCode,
  );

  factory ApiResponse.error(String error, [int? statusCode]) => ApiResponse._(
    status: ApiStatus.error,
    error: error,
    statusCode: statusCode,
  );

  factory ApiResponse.loading() => const ApiResponse._(
    status: ApiStatus.loading,
  );

  factory ApiResponse.idle() => const ApiResponse._(
    status: ApiStatus.idle,
  );

  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;
  bool get isIdle => status == ApiStatus.idle;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  
  ApiException(this.message, [this.statusCode, this.originalError]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class NetworkInfo {
  static bool get hasConnection => true; // À implémenter avec connectivity_plus
}

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('🚀 API Request: ${options.method} ${options.path}');
    if (options.data != null) {
      debugPrint('📤 Data: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('❌ API Error: ${err.message}');
    super.onError(err, handler);
  }
}
