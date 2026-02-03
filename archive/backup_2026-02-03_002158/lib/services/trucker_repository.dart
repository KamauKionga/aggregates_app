import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/trucker_model.dart';

class TruckerRepository {
  static const _key = 'truckers_v1';

  static Future<void> saveTrucker(TruckerModel t) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final map = raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw));
    map[t.id] = t.toMap();
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<TruckerModel?> getByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    for (final v in map.values) {
      final m = Map<String, dynamic>.from(v);
      if (m['userId'] == userId) return TruckerModel.fromMap(m);
    }
    return null;
  }

  static Future<TruckerModel?> getById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final v = map[id];
    if (v == null) return null;
    return TruckerModel.fromMap(Map<String, dynamic>.from(v));
  }

  static Future<void> update(TruckerModel t) => saveTrucker(t);

  static Future<List<TruckerModel>> listAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    return map.values
        .map((v) => TruckerModel.fromMap(Map<String, dynamic>.from(v)))
        .toList();
  }
}
