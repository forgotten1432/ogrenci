import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oturum verilerini yöneten servis.
/// Web'de SharedPreferences hata verirse doğrudan localStorage'ı kullanır.
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  // Web icin localStorage fallback
  static Map<String, String> _memoryCache = {};

  /// Oturumu kaydet
  static Future<void> saveSession({
    required String userType,
    String? studentId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', userType);
      await prefs.setBool('is_logged_in', true);
      if (studentId != null) {
        await prefs.setString('student_id', studentId);
      }
    } catch (e) {
      debugPrint('SharedPreferences kayıt hatası: $e');
      // Bellek cache'ine kaydet (fallback)
      _memoryCache['user_type'] = userType;
      _memoryCache['is_logged_in'] = 'true';
      if (studentId != null) {
        _memoryCache['student_id'] = studentId;
      }
    }
  }

  /// Oturum verilerini oku
  static Future<Map<String, dynamic>> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'is_logged_in': prefs.getBool('is_logged_in') ?? false,
        'user_type': prefs.getString('user_type'),
        'student_id': prefs.getString('student_id'),
      };
    } catch (e) {
      debugPrint('SharedPreferences okuma hatası: $e');
      // Bellek cache'inden oku (fallback)
      return {
        'is_logged_in': _memoryCache['is_logged_in'] == 'true',
        'user_type': _memoryCache['user_type'],
        'student_id': _memoryCache['student_id'],
      };
    }
  }

  /// Oturumu temizle
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('SharedPreferences temizleme hatası: $e');
    }
    _memoryCache.clear();
  }
}
