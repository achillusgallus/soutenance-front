import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
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

  /// Crée une publicité avec upload d'image (Compatible Web/Mobile)
  Future<bool> createAdvertisement({
    required String title,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    String? linkUrl,
    bool isActive = true,
    int order = 0,
    String type = 'general',
    DateTime? startDate,
  }) async {
    try {
      Map<String, dynamic> dataMap = {
        "title": title,
        "description": description,
        "link_url": linkUrl,
        "is_active": isActive ? 1 : 0,
        "order": order,
        "type": type,
        "start_date": startDate?.toIso8601String(),
      };

      if (kIsWeb && imageBytes != null) {
        dataMap["image"] = MultipartFile.fromBytes(
          imageBytes,
          filename: fileName ?? 'upload.jpg',
        );
      } else if (imageFile != null) {
        dataMap["image"] = await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName ?? p.basename(imageFile.path),
        );
      }

      FormData formData = FormData.fromMap(dataMap);

      final response = await _api.dio.post(
        '/admin/advertisements',
        data: formData,
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(_api.handleError(e));
    } catch (e) {
      throw Exception("Erreur inconnue: $e");
    }
  }

  /// Met à jour une publicité existante (Compatible Web/Mobile)
  Future<bool> updateAdvertisement(
    int id, {
    String? title,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    String? linkUrl,
    bool? isActive,
    int? order,
    String? type,
    DateTime? startDate,
  }) async {
    try {
      Map<String, dynamic> dataMap = {};
      if (title != null) dataMap["title"] = title;
      if (description != null) dataMap["description"] = description;
      if (linkUrl != null) dataMap["link_url"] = linkUrl;
      if (isActive != null) dataMap["is_active"] = isActive ? 1 : 0;
      if (order != null) dataMap["order"] = order;
      if (type != null) dataMap["type"] = type;
      if (startDate != null)
        dataMap["start_date"] = startDate.toIso8601String();

      if (kIsWeb && imageBytes != null) {
        dataMap["image"] = MultipartFile.fromBytes(
          imageBytes,
          filename: fileName ?? 'upload.jpg',
        );
      } else if (imageFile != null) {
        dataMap["image"] = await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName ?? p.basename(imageFile.path),
        );
      }

      FormData formData = FormData.fromMap(dataMap);

      final response = await _api.dio.post(
        '/admin/advertisements/$id',
        data: formData,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_api.handleError(e));
    } catch (e) {
      throw Exception("Erreur inconnue: $e");
    }
  }

  /// Supprime une publicité
  Future<bool> deleteAdvertisement(int id) async {
    try {
      final response = await _api.delete('/admin/advertisements/$id');
      return response?.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_api.handleError(e));
    } catch (e) {
      throw Exception("Erreur inconnue: $e");
    }
  }
}
