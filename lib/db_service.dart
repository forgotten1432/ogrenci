import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class DbService {
  static const String _key = 'quran_tables_v1';

  static Future<List<QuranTable>> getTables() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => QuranTable.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveTables(List<QuranTable> tables) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(tables.map((e) => e.toJson()).toList()));
  }
}
