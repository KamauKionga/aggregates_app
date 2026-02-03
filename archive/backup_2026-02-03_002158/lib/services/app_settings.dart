import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _key = 'app_settings_v1';

  Map<String, int> prices = {
    'Dust (0-6 mm)': 1100,
    '1/4 Inch (~6mm)': 1100,
    '1/2 Inch (~12mm)': 1100,
    '3/4 Inch (~19mm)': 1100,
    '1 Inch (~25mm)': 1100,
  };

  int tonsPerVehicle = 14;
  double transportRatePerKm = 370.0;

  AppSettings();

  static Future<AppSettings> load() async {
    final s = AppSettings();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        s.tonsPerVehicle = map['tonsPerVehicle'] ?? s.tonsPerVehicle;
        s.transportRatePerKm = (map['transportRatePerKm'] ?? s.transportRatePerKm) + 0.0;
        final p = Map<String, dynamic>.from(map['prices'] ?? {});
        s.prices = p.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }
    return s;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'prices': prices,
      'tonsPerVehicle': tonsPerVehicle,
      'transportRatePerKm': transportRatePerKm,
    };
    await prefs.setString(_key, jsonEncode(map));
  }
}
