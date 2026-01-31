import 'package:togoschool/services/service_api.dart';

class AchievementService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getAchievements() async {
    try {
      final response = await _api.read('/student/achievements');
      if (response != null && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Erreur récupération succès: $e');
      return {};
    }
  }
}
