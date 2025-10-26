import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/service_shared_preferences.dart';

class ServiceSharedPreferencesImpl implements ServiceSharedPreferences {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<String?> readString(String key) async {
    final SharedPreferences prefs = await _instance();
    return prefs.getString(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final SharedPreferences prefs = await _instance();
    await prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final SharedPreferences prefs = await _instance();
    await prefs.remove(key);
  }
}
