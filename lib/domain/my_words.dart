import 'dart:convert';

import 'answer_checker.dart';

/// A word or phrase the learner added to the personal dictionary.
/// Only [text] is required, so a word can be saved in a few seconds.
class MyWord {
  const MyWord({
    required this.id,
    required this.text,
    required this.createdAt,
    this.translation = '',
    this.ipa = '',
    this.example = '',
    this.exampleTranslation = '',
    this.category = '',
    this.learned = false,
  });

  factory MyWord.fromJson(Map<String, dynamic> json) {
    return MyWord(
      id: json['id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      translation: (json['translation'] ?? '') as String,
      ipa: (json['ipa'] ?? '') as String,
      example: (json['example'] ?? '') as String,
      exampleTranslation: (json['exampleTranslation'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      learned: (json['learned'] ?? false) as bool,
    );
  }

  final String id;
  final String text;
  final DateTime createdAt;
  final String translation;
  final String ipa;
  final String example;
  final String exampleTranslation;
  final String category;
  final bool learned;

  MyWord copyWith({
    String? text,
    String? translation,
    String? ipa,
    String? example,
    String? exampleTranslation,
    String? category,
    bool? learned,
  }) {
    return MyWord(
      id: id,
      createdAt: createdAt,
      text: text ?? this.text,
      translation: translation ?? this.translation,
      ipa: ipa ?? this.ipa,
      example: example ?? this.example,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      category: category ?? this.category,
      learned: learned ?? this.learned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'translation': translation,
        'ipa': ipa,
        'example': example,
        'exampleTranslation': exampleTranslation,
        'category': category,
        'learned': learned,
      };
}

String encodeMyWords(List<MyWord> words) => jsonEncode([for (final word in words) word.toJson()]);

List<MyWord> decodeMyWords(String raw) {
  final list = jsonDecode(raw) as List;
  return [for (final item in list) MyWord.fromJson(item as Map<String, dynamic>)];
}

/// The saved word with the same text (case and punctuation ignored), if any.
/// [exceptId] skips the word being edited.
MyWord? findDuplicate(Iterable<MyWord> words, String text, {String? exceptId}) {
  final wanted = normalizeAnswer(text);
  if (wanted.isEmpty) return null;
  for (final word in words) {
    if (word.id != exceptId && normalizeAnswer(word.text) == wanted) return word;
  }
  return null;
}

/// Categories in use, without repeats, in alphabetical order.
List<String> categoriesOf(Iterable<MyWord> words) {
  final found = <String>{
    for (final word in words)
      if (word.category.trim().isNotEmpty) word.category.trim(),
  };
  return found.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

/// Words matching the search text and filters, in alphabetical order.
/// The search looks in the word, its translation and its example.
List<MyWord> filterMyWords(
  List<MyWord> words, {
  String query = '',
  String? category,
  bool hideLearned = false,
}) {
  final needle = query.trim().toLowerCase();
  final result = [
    for (final word in words)
      if ((category == null || word.category.trim() == category) &&
          (!hideLearned || !word.learned) &&
          (needle.isEmpty ||
              word.text.toLowerCase().contains(needle) ||
              word.translation.toLowerCase().contains(needle) ||
              word.example.toLowerCase().contains(needle)))
        word,
  ];
  result.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
  return result;
}
