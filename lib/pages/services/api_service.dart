import 'package:dio/dio.dart';

import 'package:togoschool/pages/models/user_model.dart'; // Import du modèle

class ApiService {
  final Dio _dio = Dio();
  final String _baseUrl = "http://127.0.0.1:8000/api";

  //inscription
  Future<User> registerStudent({
    required String nom,
    required String prenom,
    required String classe,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/register',
        data: {
          'nom': nom,
          'prenom': prenom,
          'classe': classe,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // final token = response.data['token'];

        // Récupère les données utilisateur depuis la réponse
        final userData = response.data['user'];
        final user = User.fromJson(userData); // Convertit en User

        return user; // Retourne l'objet User
      } else {
        throw Exception("Erreur serveur : ${response.statusMessage}");
      }
    } on DioException catch (e) {
      throw Exception("Erreur de connexion : ${e.message}");
    } catch (e) {
      throw Exception("Erreur inattendue : $e");
    }
  }



  //connection
}