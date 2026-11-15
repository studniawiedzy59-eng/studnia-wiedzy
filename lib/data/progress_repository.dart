import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/progress.dart';

/// Keeps the learner's progress on the device so lessons work without a network.
class ProgressRepository {
  static const _key = 'progress_v1';

  Future<Progress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const Progress.empty();
    try {
      return Progress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const Progress.empty();
    }
  }

  Future<void> save(Progress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(progress.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
