import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/learner_profile.dart';

/// Keeps the quiz answers on the device. `null` means the quiz was never finished.
class LearnerProfileRepository {
  static const _key = 'learner_profile_v1';

  Future<LearnerProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return LearnerProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(LearnerProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}
