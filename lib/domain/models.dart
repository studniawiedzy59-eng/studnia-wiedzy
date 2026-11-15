import 'answer_checker.dart';

/// Text shown in the learner's explanation language.
class L10nText {
  const L10nText(this.values);

  factory L10nText.fromJson(Object? json) {
    if (json is String) return L10nText({'uk': json});
    if (json is Map) {
      return L10nText(json.map((k, v) => MapEntry(k.toString(), v.toString())));
    }
    throw FormatException('Invalid localized text: $json');
  }

  final Map<String, String> values;

  String of(String lang) {
    return values[lang] ?? values['uk'] ?? (values.isEmpty ? '' : values.values.first);
  }
}

/// A list of options that is either the same for everyone (target-language
/// words) or differs by explanation language (translations).
class L10nList {
  const L10nList(this.values);

  factory L10nList.fromJson(Object? json) {
    if (json is List) {
      return L10nList({'*': json.map((e) => e.toString()).toList()});
    }
    if (json is Map) {
      return L10nList(json.map(
        (k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
      ));
    }
    throw FormatException('Invalid option list: $json');
  }

  final Map<String, List<String>> values;

  List<String> of(String lang) => values['*'] ?? values[lang] ?? values['uk'] ?? const [];
}

class Word {
  const Word({
    required this.id,
    required this.text,
    required this.ipa,
    required this.pos,
    required this.translation,
    required this.example,
    required this.exampleTranslation,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      text: json['text'] as String,
      ipa: json['ipa'] as String,
      pos: json['pos'] as String,
      translation: L10nText.fromJson(json['translation']),
      example: json['example'] as String,
      exampleTranslation: L10nText.fromJson(json['exampleTranslation']),
    );
  }

  final String id;
  final String text;
  final String ipa;
  final String pos;
  final L10nText translation;
  final String example;
  final L10nText exampleTranslation;
}

sealed class Exercise {
  const Exercise({required this.id, required this.prompt, required this.explanation});

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final prompt = L10nText.fromJson(json['prompt']);
    final explanation = L10nText.fromJson(json['explanation']);
    switch (json['type'] as String) {
      case 'multiple_choice':
      case 'listening':
        return ChoiceExercise(
          id: id,
          prompt: prompt,
          explanation: explanation,
          options: L10nList.fromJson(json['options']),
          answerIndex: json['answer'] as int,
          audioText: json['audioText'] as String?,
        );
      case 'fill_blank':
        return FillBlankExercise(
          id: id,
          prompt: prompt,
          explanation: explanation,
          sentence: json['sentence'] as String,
          options: (json['options'] as List).map((e) => e.toString()).toList(),
          answerIndex: json['answer'] as int,
        );
      case 'matching':
        return MatchingExercise(
          id: id,
          prompt: prompt,
          explanation: explanation,
          pairs: (json['pairs'] as List)
              .map((p) => MatchPair(
                    left: (p as Map)['left'] as String,
                    right: L10nText.fromJson(p['right']),
                  ))
              .toList(),
        );
      case 'build_sentence':
        return BuildSentenceExercise(
          id: id,
          prompt: prompt,
          explanation: explanation,
          words: (json['words'] as List).map((e) => e.toString()).toList(),
          answer: (json['answer'] as List).map((e) => e.toString()).toList(),
        );
      case 'translate':
        return TranslateExercise(
          id: id,
          prompt: prompt,
          explanation: explanation,
          answers: (json['answers'] as List).map((e) => e.toString()).toList(),
        );
      default:
        throw FormatException('Unknown exercise type: ${json['type']}');
    }
  }

  final String id;
  final L10nText prompt;
  final L10nText explanation;

  /// Whether [answer], as reported by the exercise widget, is correct.
  bool check(Object? answer);

  /// The correct answer as text, shown after a mistake.
  String correctAnswer(String lang);
}

/// Multiple choice. With [audioText] set it is a listening exercise.
class ChoiceExercise extends Exercise {
  const ChoiceExercise({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.options,
    required this.answerIndex,
    this.audioText,
  });

  final L10nList options;
  final int answerIndex;
  final String? audioText;

  bool get isListening => audioText != null;

  @override
  bool check(Object? answer) => answer == answerIndex;

  @override
  String correctAnswer(String lang) => options.of(lang)[answerIndex];
}

class FillBlankExercise extends Exercise {
  const FillBlankExercise({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.sentence,
    required this.options,
    required this.answerIndex,
  });

  final String sentence;
  final List<String> options;
  final int answerIndex;

  @override
  bool check(Object? answer) => answer == answerIndex;

  @override
  String correctAnswer(String lang) => sentence.replaceFirst('___', options[answerIndex]);
}

class MatchPair {
  const MatchPair({required this.left, required this.right});

  final String left;
  final L10nText right;
}

class MatchingExercise extends Exercise {
  const MatchingExercise({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.pairs,
  });

  final List<MatchPair> pairs;

  /// The widget reports `true` when every pair was matched without a mistake.
  @override
  bool check(Object? answer) => answer == true;

  @override
  String correctAnswer(String lang) {
    return pairs.map((p) => '${p.left} — ${p.right.of(lang)}').join('; ');
  }
}

class BuildSentenceExercise extends Exercise {
  const BuildSentenceExercise({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.words,
    required this.answer,
  });

  final List<String> words;
  final List<String> answer;

  @override
  bool check(Object? answer) {
    if (answer is! List) return false;
    if (answer.length != this.answer.length) return false;
    for (var i = 0; i < answer.length; i++) {
      if (answer[i] != this.answer[i]) return false;
    }
    return true;
  }

  @override
  String correctAnswer(String lang) => answer.join(' ');
}

class TranslateExercise extends Exercise {
  const TranslateExercise({
    required super.id,
    required super.prompt,
    required super.explanation,
    required this.answers,
  });

  final List<String> answers;

  @override
  bool check(Object? answer) => answer is String && matchesAnyAnswer(answer, answers);

  @override
  String correctAnswer(String lang) => answers.first;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.unitId,
    required this.cefr,
    required this.title,
    required this.goal,
    required this.rule,
    required this.words,
    required this.exercises,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      unitId: json['unit'] as String,
      cefr: json['cefr'] as String,
      title: L10nText.fromJson(json['title']),
      goal: L10nText.fromJson(json['goal']),
      rule: L10nText.fromJson(json['rule']),
      words: (json['words'] as List)
          .map((w) => Word.fromJson(Map<String, dynamic>.from(w as Map)))
          .toList(),
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  final String id;
  final String unitId;
  final String cefr;
  final L10nText title;
  final L10nText goal;
  final L10nText rule;
  final List<Word> words;
  final List<Exercise> exercises;
}

class CourseUnit {
  const CourseUnit({
    required this.id,
    required this.cefr,
    required this.title,
    required this.lessonIds,
  });

  factory CourseUnit.fromJson(Map<String, dynamic> json) {
    return CourseUnit(
      id: json['id'] as String,
      cefr: json['cefr'] as String,
      title: L10nText.fromJson(json['title']),
      lessonIds: (json['lessons'] as List).map((e) => e.toString()).toList(),
    );
  }

  final String id;
  final String cefr;
  final L10nText title;
  final List<String> lessonIds;
}

class Course {
  const Course({required this.id, required this.units});

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      units: (json['units'] as List)
          .map((u) => CourseUnit.fromJson(Map<String, dynamic>.from(u as Map)))
          .toList(),
    );
  }

  final String id;
  final List<CourseUnit> units;

  List<String> get lessonIds => [for (final unit in units) ...unit.lessonIds];
}
