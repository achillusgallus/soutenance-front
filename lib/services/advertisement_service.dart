import 'dart:io';
import 'package:dio/dio.dart';
import 'package:togoschool/models/advertisement.dart';
import 'package:togoschool/services/service_api.dart';

class AdvertisementService {
  final ApiService _api = ApiService();

  /// Récupère la liste des publicités actives (pour l'élève)
  Future<List<Advertisement>> getAdvertisements() async {
    try {
      final response = await _api.read('/advertisements');

      if (response != null && response.data != null) {
        final dynamic data = response.data;
        if (data is List) {
          return data.map((json) => Advertisement.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des publicités: $e');
      return [];
    }
  }

  // --- MÉTHODES ADMINISTRATION ---

  /// Récupère toutes les publicités (pour l'admin)
  Future<List<Advertisement>> getAllAdvertisementsAdmin() async {
    try {
      final response = await _api.read('/admin/advertisements');

      if (response != null && response.data != null) {
        final dynamic data = response.data;
        if (data is List) {
          return data.map((json) => Advertisement.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération admin des publicités: $e');
      return [];
    }
  }

  /// Crée une publicité avec upload d'image
  Future<bool> createAdvertisement({
    required String title,
    String? description,
    required File imageFile,
    String? linkUrl,
    bool isActive = true,
    int order = 0,
  }) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "title": title,
        "description": description,
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        "link_url": linkUrl,
        "is_active": isActive ? 1 : 0,
        "order": order,
      });

      final response = await _api.dio.post(
        '/admin/advertisements',
        data: formData,
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Erreur lors de la création de la publicité: $e');
      return false;
    }
  }

  /// Met à jour une publicité existante (incluant potentiellement une image)
  Future<bool> updateAdvertisement(
    int id, {
    String? title,
    String? description,
    File? imageFile,
    String? linkUrl,
    bool? isActive,
    int? order,
  }) async {
    try {
      Map<String, dynamic> dataMap = {};
      if (title != null) dataMap["title"] = title;
      if (description != null) dataMap["description"] = description;
      if (linkUrl != null) dataMap["link_url"] = linkUrl;
      if (isActive != null) dataMap["is_active"] = isActive ? 1 : 0;
      if (order != null) dataMap["order"] = order;

      if (imageFile != null) {
        String fileName = imageFile.path.split('/').last;
        dataMap["image"] = await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        );
      }

      FormData formData = FormData.fromMap(dataMap);

      // On utilise POST car certains serveurs/frameworks ont du mal avec multipart sur PUT/PATCH
      final response = await _api.dio.post(
        '/admin/advertisements/$id',
        data: formData,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour de la publicité: $e');
      return false;
    }
  }

  /// Supprime une publicité
  Future<bool> deleteAdvertisement(int id) async {
    try {
      final response = await _api.delete('/admin/advertisements/$id');
      return response?.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la suppression de la publicité: $e');
      return false;
    }
  }
}
