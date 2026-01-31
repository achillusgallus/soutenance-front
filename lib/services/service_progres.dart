import 'package:hive_flutter/hive_flutter.dart';
import 'package:togoschool/services/service_api.dart';

class ProgressService {
  static const String _boxName = 'student_progress';
  final ApiService _api = ApiService();

  Future<List<dynamic>?> getProgressFromServer() async {
    try {
      final response = await _api.read('/student/progress');
      if (response?.data is List) {
        return response!.data;
      }
      return null;
    } catch (e) {
      print('Erreur récupération progression: $e');
      return null;
    }
  }

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

  Future<Map<String, dynamic>?> getLocalProgress(int courseId) async {
    final box = await Hive.openBox(_boxName);
    return box.get('course_$courseId');
  }

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
