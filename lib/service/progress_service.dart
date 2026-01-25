import 'package:hive_flutter/hive_flutter.dart';
import 'package:togoschool/service/api_service.dart';

class ProgressService {
  static const String _boxName = 'student_progress';
  final ApiService _api = ApiService();

  // Récupérer la progression depuis le serveur
  Future<Map<String, dynamic>?> getProgressFromServer() async {
    try {
      final response = await _api.read('/student/progress');
      return response?.data;
    } catch (e) {
      print('Erreur récupération progression: $e');
      return null;
    }
  }

  // Sauvegarder la progression localement
  Future<void> saveProgressLocally(
    int courseId,
    int progress,
    int timeSpent,
  ) async {
    final box = await Hive.openBox(_boxName);
    await box.put('course_$courseId', {
      'progress': progress,
      'time_spent': timeSpent,
      'last_accessed': DateTime.now().toIso8601String(),
    });
  }

  // Récupérer la progression locale
  Future<Map<String, dynamic>?> getLocalProgress(int courseId) async {
    final box = await Hive.openBox(_boxName);
    return box.get('course_$courseId');
  }

  // Synchroniser avec le serveur
  Future<void> syncProgress() async {
    try {
      final box = await Hive.openBox(_boxName);
      final allProgress = box.toMap();

      for (var entry in allProgress.entries) {
        if (entry.key.toString().startsWith('course_')) {
          final courseId = entry.key.toString().replaceFirst('course_', '');
          await _api.create('/student/progress', {
            'course_id': courseId,
            'progress': entry.value['progress'],
            'time_spent': entry.value['time_spent'],
          });
        }
      }
    } catch (e) {
      print('Erreur synchronisation: $e');
    }
  }

  // Marquer un cours comme favori
  Future<bool> toggleFavorite(int courseId) async {
    try {
      final response = await _api.create('/student/favorites/toggle', {
        'course_id': courseId,
      });
      return response?.statusCode == 200;
    } catch (e) {
      print('Erreur toggle favori: $e');
      return false;
    }
  }

  // Récupérer les favoris
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _api.read('/student/favorites');
      if (response?.data is List) {
        return response!.data;
      } else if (response?.data is Map && response!.data.containsKey('data')) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print('Erreur récupération favoris: $e');
      return [];
    }
  }

  // Sauvegarder une note
  Future<bool> saveNote(int courseId, String content) async {
    try {
      final response = await _api.create('/student/notes', {
        'course_id': courseId,
        'content': content,
      });
      return response?.statusCode == 200 || response?.statusCode == 201;
    } catch (e) {
      print('Erreur sauvegarde note: $e');
      return false;
    }
  }

  // Récupérer les notes d'un cours
  Future<List<dynamic>> getNotes(int courseId) async {
    try {
      final response = await _api.read('/student/notes/$courseId');
      if (response?.data is List) {
        return response!.data;
      } else if (response?.data is Map && response!.data.containsKey('data')) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print('Erreur récupération notes: $e');
      return [];
    }
  }

  // Récupérer les statistiques
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await _api.read('/student/stats');
      return response?.data;
    } catch (e) {
      print('Erreur récupération stats: $e');
      return null;
    }
  }
}
