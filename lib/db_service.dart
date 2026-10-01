import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class DbService {
  static const String _key = 'quran_groups_v3';

  static Future<List<Group>> getGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Group.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveGroups(List<Group> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(groups.map((e) => e.toJson()).toList()));
  }
}
