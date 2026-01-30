import 'package:togoschool/models/advertisement.dart';
import 'package:togoschool/services/api_service.dart';

class AdvertisementService {
  final ApiService _api = ApiService();

  Future<List<Advertisement>> getAdvertisements() async {
    try {
      final response = await _api.read('/advertisements');
      if (response?.data is List) {
        return (response!.data as List)
            .map((json) => Advertisement.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erreur publicités: $e');
      return [];
    }
  }
}
