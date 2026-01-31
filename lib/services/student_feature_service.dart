import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:togoschool/services/service_api.dart';

class StudentFeatureService {
  final _api = ApiService();

  // --- ÉLÈVE ---

  Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await _api.read('/student/leaderboard');
      return response?.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDiscoveryResource() async {
    try {
      final response = await _api.read('/student/discovery');
      return response?.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getEducationalNews() async {
    try {
      final response = await _api.read('/student/news');
      return response?.data ?? [];
    } catch (e) {
      return [];
    }
  }

  // --- ADMINISTRATION ---

  /// Ressources Découverte
  Future<List<dynamic>> getAllDiscoveryAdmin() async {
    try {
      final response = await _api.read('/admin/discovery');
      return response?.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createDiscovery({
    required String title,
    required String type,
    required String content,
    required String displayDate,
  }) async {
    try {
      final response = await _api.create('/admin/discovery', {
        'title': title,
        'type': type,
        'content': content,
        'display_date': displayDate,
      });
      return response?.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(_api.handleError(e));
    } catch (e) {
      throw Exception("Erreur inconnue: $e");
    }
  }

  Future<bool> deleteDiscovery(int id) async {
    try {
      final response = await _api.delete('/admin/discovery/$id');
      return response?.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_api.handleError(e));
    } catch (e) {
      throw Exception("Erreur inconnue: $e");
    }
  }

  /// Actualités Éducatives
  Future<List<dynamic>> getAllNewsAdmin() async {
    try {
      final response = await _api.read('/admin/news');
      return response?.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createNews({
    required String title,
    required String content,
    int? matiereId,
    File? image,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    try {
      Map<String, dynamic> data = {'title': title, 'content': content};
      if (matiereId != null) data['matiere_id'] = matiereId;

      if (kIsWeb && imageBytes != null) {
        data['image'] = MultipartFile.fromBytes(
          imageBytes,
          filename: fileName ?? 'news.jpg',
        );
      } else if (image != null) {
        data['image'] = await MultipartFile.fromFile(
          image.path,
          filename: fileName ?? p.basename(image.path),
        );
      }

      FormData formData = FormData.fromMap(data);
      final response = await _api.dio.post('/admin/news', data: formData);
      return response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(_api.handleError(e));
    } catch (e) {
      throw Exception("Erreur inconnue: $e");
    }
  }

  Future<bool> deleteNews(int id) async {
    try {
      final response = await _api.delete('/admin/news/$id');
      return response?.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_api.handleError(e));
    } catch (e) {
      throw Exception("Erreur inconnue: $e");
    }
  }
}
