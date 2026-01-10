import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les téléchargements de cours
class DownloadService {
  static const String _downloadCountKey = 'download_count';
  static const int _maxFreeDownloads = 3;

  /// Récupérer le nombre de téléchargements effectués
  static Future<int> getDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_downloadCountKey) ?? 0;
  }

  /// Incrémenter le compteur de téléchargements
  static Future<void> incrementDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getDownloadCount();
    await prefs.setInt(_downloadCountKey, currentCount + 1);
  }

  /// Vérifier si l'utilisateur peut encore télécharger gratuitement
  static Future<bool> canDownloadFree() async {
    final count = await getDownloadCount();
    return count < _maxFreeDownloads;
  }

  /// Obtenir le nombre de téléchargements restants
  static Future<int> getRemainingDownloads() async {
    final count = await getDownloadCount();
    final remaining = _maxFreeDownloads - count;
    return remaining > 0 ? remaining : 0;
  }

  /// Réinitialiser le compteur (après paiement par exemple)
  static Future<void> resetDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadCountKey);
  }

  /// Obtenir le nombre maximum de téléchargements gratuits
  static int get maxFreeDownloads => _maxFreeDownloads;
}
