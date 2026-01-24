import 'dart:io';
import 'package:dio/dio.dart';
import 'package:togoschool/service/token_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late Dio dio;

  ApiService() {
    String baseUrl;

    // URL DE PRODUCTION (Render)
    // Pour tester en local avec le serveur distant, décommentez la ligne suivante et commentez le bloc if/else
    baseUrl = "https://backend-togoschool.onrender.com/api";

    /* 
    // SERVER LOCAL DEV
    if (kIsWeb) {
      baseUrl = "https://backend-togoschool.onrender.com/api";
    } else if (Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:8000/api";
    } else if (Platform.isIOS) {
      baseUrl = "http://localhost:8000/api";
    } else {
      baseUrl = "http://localhost:8000/api";
    } 
    */

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
          // Tu peux modifier la requête ici si besoin
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Tu peux transformer la réponse ici si besoin
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Gestion centralisée des erreurs
          print("Erreur interceptée: ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  // Méthode pour gérer les erreurs proprement
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

  // CREATE
  Future<Response?> create(String endpoint, dynamic data) async {
    try {
      return await dio.post(endpoint, data: data);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  // READ
  Future<Response?> read(String endpoint) async {
    try {
      return await dio.get(endpoint);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  // UPDATE
  Future<Response?> update(String endpoint, dynamic data) async {
    try {
      return await dio.put(endpoint, data: data);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  // DELETE
  Future<Response?> delete(String endpoint) async {
    try {
      return await dio.delete(endpoint);
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }

  // Récupérer l’URL sécurisée d’un fichier via l’API backend
  Future<String?> getFileUrl(String filePath) async {
    try {
      final response = await dio.get("/student/file/$filePath");

      if (response.statusCode == 200 && response.data != null) {
        return response.data['url']; // L’URL complète renvoyée par le backend
      } else {
        return null;
      }
    } on DioException catch (e) {
      throw Exception(handleError(e));
    }
  }
}
