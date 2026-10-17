import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ThemeController instance = ThemeController._();
  ThemeController._();
  final ValueNotifier<bool> isDark = ValueNotifier(false);
  static const _key = 'dark_mode';
  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsAsync() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final p = await _prefsAsync();
    isDark.value = p.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    isDark.value = !isDark.value;
    final p = await _prefsAsync();
    await p.setBool(_key, isDark.value);
  }

  Future<void> setDark(bool v) async {
    isDark.value = v;
    final p = await _prefsAsync();
    await p.setBool(_key, v);
  }
}
