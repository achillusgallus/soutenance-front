import 'package:shared_preferences/shared_preferences.dart';

class DownloadService {
  static const String _downloadCountKey = 'download_count';
  static const int _maxFreeDownloads = 3;

  static Future<int> getDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_downloadCountKey) ?? 0;
  }

  static Future<void> incrementDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = await getDownloadCount();
    await prefs.setInt(_downloadCountKey, currentCount + 1);
  }

  static Future<bool> canDownloadFree() async {
    final count = await getDownloadCount();
    return count < _maxFreeDownloads;
  }

  static Future<int> getRemainingDownloads() async {
    final count = await getDownloadCount();
    final remaining = _maxFreeDownloads - count;
    return remaining > 0 ? remaining : 0;
  }

  static Future<void> resetDownloadCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadCountKey);
  }

  static int get maxFreeDownloads => _maxFreeDownloads;
}


