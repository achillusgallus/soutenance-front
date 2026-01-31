import 'package:togoschool/services/service_api.dart';

class StudentFeatureService {
  final _api = ApiService();

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
}
