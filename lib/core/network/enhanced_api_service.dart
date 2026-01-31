import 'package:dio/dio.dart';
import 'package:togoschool/services/stockage_jeton.dart';
import 'package:togoschool/core/network/network_result.dart';
import 'package:flutter/foundation.dart';

class EnhancedApiService {
  late Dio _dio;
  static const Duration _defaultTimeout = Duration(seconds: 30);

  EnhancedApiService({String? baseUrl}) {
    final effectiveBaseUrl = baseUrl ?? _getBaseUrl();

    _dio = Dio(
      BaseOptions(
        baseUrl: effectiveBaseUrl,
        connectTimeout: _defaultTimeout,
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: _defaultTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );

    _setupInterceptors();
  }

  String _getBaseUrl() {
    if (kIsWeb) {
      return "https://backend-togoschool.onrender.com/api";
    }
    return "https://backend-togoschool.onrender.com/api";
  }

  void _setupInterceptors() {
    _dio.interceptors.add(ApiInterceptor());

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          options.headers['X-Client-Version'] = '1.0.0';
          options.headers['X-Platform'] = kIsWeb ? 'web' : 'mobile';

          return handler.next(options);
        },
        onError: (error, handler) {
          final apiException = _handleError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: apiException,
              message: apiException.message,
              type: error.type,
              response: error.response,
            ),
          );
        },
      ),
    );
  }

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Délai de connexion dépassé. Vérifiez votre connexion.',
          error.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(error);

      case DioExceptionType.cancel:
        return ApiException('Requête annulée', error.response?.statusCode);

      case DioExceptionType.connectionError:
        return ApiException(
          'Erreur de connexion. Vérifiez votre internet.',
          error.response?.statusCode,
        );

      case DioExceptionType.unknown:
        return ApiException(
          'Erreur réseau inconnue. Réessayez plus tard.',
          error.response?.statusCode,
        );

      default:
        return ApiException(
          'Erreur inattendue: ${error.message}',
          error.response?.statusCode,
        );
    }
  }

  ApiException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'Erreur serveur';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;

      if (data['errors'] is Map) {
        final errors = data['errors'] as Map<String, dynamic>;
        final firstError = errors.values.firstWhere(
          (v) => v != null,
          orElse: () => null,
        );
        if (firstError != null) {
          message = firstError.toString();
        }
      }
    }

    switch (statusCode) {
      case 400:
        return ApiException('Requête invalide: $message', statusCode);
      case 401:
        return ApiException(
          'Session expirée. Veuillez vous reconnecter.',
          statusCode,
        );
      case 403:
        return ApiException(
          'Accès refusé. Permissions insuffisantes.',
          statusCode,
        );
      case 404:
        return ApiException('Ressource non trouvée.', statusCode);
      case 422:
        return ApiException('Données invalides: $message', statusCode);
      case 429:
        return ApiException(
          'Trop de requêtes. Attendez avant de réessayer.',
          statusCode,
        );
      case 500:
        return ApiException(
          'Erreur serveur interne. Réessayez plus tard.',
          statusCode,
        );
      case 503:
        return ApiException('Service temporairement indisponible.', statusCode);
      default:
        return ApiException(message, statusCode);
    }
  }

  Future<ApiResponse<T>> _makeRequest<T>(
    Future<Response> Function() request,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final response = await request();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = fromJson(response.data);
        return ApiResponse.success(data, response.statusCode);
      } else {
        return ApiResponse.error(
          'Réponse inattendue: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      final apiException =
          e.error as ApiException? ??
          ApiException('Erreur réseau: ${e.message}', e.response?.statusCode);
      return ApiResponse.error(apiException.message, apiException.statusCode);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _makeRequest(
      () => _dio.get(endpoint, queryParameters: queryParameters),
      fromJson,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _makeRequest(
      () => _dio.post(endpoint, data: data, queryParameters: queryParameters),
      fromJson,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _makeRequest(
      () => _dio.put(endpoint, data: data, queryParameters: queryParameters),
      fromJson,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(dynamic) fromJson, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _makeRequest(
      () => _dio.delete(endpoint, queryParameters: queryParameters),
      fromJson,
    );
  }

  Future<ApiResponse<void>> deleteVoid(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null, response.statusCode);
      } else {
        return ApiResponse.error(
          'Réponse inattendue: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      final apiException =
          e.error as ApiException? ??
          ApiException('Erreur réseau: ${e.message}', e.response?.statusCode);
      return ApiResponse.error(apiException.message, apiException.statusCode);
    } catch (e) {
      return ApiResponse.error('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<Response?> downloadFile(String url, String savePath) async {
    try {
      return await _dio.download(url, savePath);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
