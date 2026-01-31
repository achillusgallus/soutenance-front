import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CacheManager {
  static const String _cachePrefix = '_cache_';
  static const String _timestampPrefix = '_timestamp_';
  static const Duration _defaultCacheDuration = Duration(hours: 1);

  static Future<void> set<T>(
    String key,
    T value, {
    Duration? duration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      
      final jsonString = _encodeValue(value);
      final expiryTime = DateTime.now().add(duration ?? _defaultCacheDuration);
      
      await prefs.setString(cacheKey, jsonString);
      await prefs.setString(timestampKey, expiryTime.toIso8601String());
      
      if (kDebugMode) {
        print('Cache SET: $key (expires: $expiryTime)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache SET Error for $key: $e');
      }
    }
  }

  static Future<T?> get<T>(String key, T Function(dynamic) fromJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      
      final cachedData = prefs.getString(cacheKey);
      final timestamp = prefs.getString(timestampKey);
      
      if (cachedData == null || timestamp == null) {
        if (kDebugMode) {
          print('Cache MISS: $key (no data)');
        }
        return null;
      }
      
      final expiryTime = DateTime.parse(timestamp);
      if (DateTime.now().isAfter(expiryTime)) {
        await remove(key);
        if (kDebugMode) {
          print('Cache MISS: $key (expired)');
        }
        return null;
      }
      
      final value = _decodeValue(cachedData, fromJson);
      if (kDebugMode) {
        print('Cache HIT: $key');
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        print('Cache GET Error for $key: $e');
      }
      return null;
    }
  }

  static Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
      
      if (kDebugMode) {
        print('Cache REMOVE: $key');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Cache REMOVE Error for $key: $e');
      }
      return false;
    }
  }

  static Future<bool> exists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '$_timestampPrefix$key';
      final timestamp = prefs.getString(timestampKey);
      
      if (timestamp == null) return false;
      
      final expiryTime = DateTime.parse(timestamp);
      if (DateTime.now().isAfter(expiryTime)) {
        await remove(key);
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
      
      if (kDebugMode) {
        print('Cache CLEARED');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache CLEAR Error: $e');
      }
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int size = 0;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final value = prefs.getString(key);
          if (value != null) {
            size += value.length;
          }
        }
      }
      
      return size;
    } catch (e) {
      return 0;
    }
  }

  static String _encodeValue<T>(T value) {
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return jsonEncode(value);
  }

  static T _decodeValue<T>(String encodedValue, T Function(dynamic) fromJson) {
    try {
      if (encodedValue.startsWith('{') || encodedValue.startsWith('[')) {
        return fromJson(jsonDecode(encodedValue));
      }
      
      if (T == String) return encodedValue as T;
      if (T == int) return int.parse(encodedValue) as T;
      if (T == double) return double.parse(encodedValue) as T;
      if (T == bool) return (encodedValue == 'true') as T;
      
      return fromJson(encodedValue);
    } catch (e) {
      throw Exception('Failed to decode cached value: $e');
    }
  }
}

class ImageCacheManager {
  static const String _imageCacheDir = 'cached_images';
  static const Duration _defaultImageCacheDuration = Duration(days: 7);

  static Future<File?> cacheImage(String url, {Duration? duration}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/$_imageCacheDir');
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      final fileName = url.hashCode.toString();
      final file = File('${imageDir.path}/$fileName');
      
      if (await file.exists()) {
        final stat = await file.stat();
        final age = DateTime.now().difference(stat.modified);
        final maxAge = duration ?? _defaultImageCacheDuration;
        
        if (age < maxAge) {
          if (kDebugMode) {
            print('Image Cache HIT: $url');
          }
          return file;
        } else {
          await file.delete();
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Image Cache Error for $url: $e');
      }
      return null;
    }
  }

  static Future<void> saveImageToCache(String url, File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/$_imageCacheDir');
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      final fileName = url.hashCode.toString();
      final cacheFile = File('${imageDir.path}/$fileName');
      
      await imageFile.copy(cacheFile.path);
      
      if (kDebugMode) {
        print('Image Cache SAVE: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Image Cache SAVE Error for $url: $e');
      }
    }
  }

  static Future<void> clearImageCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/$_imageCacheDir');
      
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }
      
      if (kDebugMode) {
        print('Image Cache CLEARED');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Image Cache CLEAR Error: $e');
      }
    }
  }
}

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _durations = {};

  static void startOperation(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  static void endOperation(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    _durations[operation] ??= [];
    _durations[operation]!.add(duration);

    if (kDebugMode) {
      print('Performance: $operation took ${duration.inMilliseconds}ms');
    }

    _startTimes.remove(operation);
  }

  static Duration? getAverageDuration(String operation) {
    final durations = _durations[operation];
    if (durations == null || durations.isEmpty) return null;

    final totalMs = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );

    return Duration(milliseconds: totalMs ~/ durations.length);
  }

  static Map<String, Duration> getAllAverageDurations() {
    final result = <String, Duration>{};
    
    for (final operation in _durations.keys) {
      final avgDuration = getAverageDuration(operation);
      if (avgDuration != null) {
        result[operation] = avgDuration;
      }
    }
    
    return result;
  }

  static void reset() {
    _startTimes.clear();
    _durations.clear();
  }

  static void logPerformanceReport() {
    if (!kDebugMode) return;

    print('\n=== PERFORMANCE REPORT ===');
    final averages = getAllAverageDurations();
    
    for (final entry in averages.entries) {
      print('${entry.key}: ${entry.value.inMilliseconds}ms (average)');
    }
    
    print('========================\n');
  }
}


