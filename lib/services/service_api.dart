import 'package:dio/dio.dart';
import 'package:togoschool/services/stockage_jeton.dart';

class ApiService {
  late Dio dio;

  ApiService() {
    String baseUrl;

    // URL DE PRODUCTION (Render)
    // Pour tester en local avec le serveur distant, décommentez la ligne suivante et commentez le bloc if/else
    baseUrl = "https://backend-togoschool.onrender.com/api";

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ),
    );

    // Interceptors
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print("Erreur interceptée: ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  String handleError(DioException error) {
    String message = "";
    if (error.response?.data != null && error.response?.data is Map) {
      message =
          error.response?.data['message'] ??
          error.response?.data['error'] ??
          "";
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return "Connexion expirée";
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return "Temps de réponse dépassé";
    } else if (error.type == DioExceptionType.badResponse) {
      return "Erreur ${error.response?.statusCode}: ${message.isNotEmpty ? message : 'Erreur serveur'}";
    } else if (error.type == DioExceptionType.cancel) {
      return "Requête annulée";
    } else {
      return "Erreur inconnue: ${error.message}";
    }
  }

  Future<Response?> create(String endpoint, dynamic data) async {
    try {
      return await dio.post(endpoint, data: data);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<Response?> read(String endpoint) async {
    try {
      return await dio.get(endpoint);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<Response?> update(String endpoint, dynamic data) async {
    try {
      return await dio.put(endpoint, data: data);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<Response?> delete(String endpoint) async {
    try {
      return await dio.delete(endpoint);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  Future<String?> getFileUrl(String filePath) async {
    try {
      final response = await dio.get("/student/file/$filePath");

      if (response.statusCode == 200 && response.data != null) {
        return response.data['url'];
      } else {
        return null;
      }
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }
}
