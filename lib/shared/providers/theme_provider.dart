import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final simpleModeProvider = StateNotifierProvider<SimpleModeNotifier, bool>((ref) {
  return SimpleModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }
}

class SimpleModeNotifier extends StateNotifier<bool> {
  SimpleModeNotifier() : super(false) {
    _loadSimpleMode();
  }

  Future<void> _loadSimpleMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('is_simple_mode') ?? false;
  }

  Future<void> toggleSimpleMode(bool isSimple) async {
    state = isSimple;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_simple_mode', isSimple);
  }
}
