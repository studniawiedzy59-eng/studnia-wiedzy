import 'package:shared_preferences/shared_preferences.dart';

import '../domain/my_words.dart';

/// Keeps the personal dictionary on the device between sessions.
class MyWordsRepository {
  static const _key = 'my_words_v1';

  Future<List<MyWord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const [];
    return decodeMyWords(raw);
  }

  Future<void> save(List<MyWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, encodeMyWords(words));
  }
}
