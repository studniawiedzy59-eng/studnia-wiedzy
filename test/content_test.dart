import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/models.dart';

Map<String, dynamic> _read(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  final course = Course.fromJson(_read('assets/content/en/course.json'));

  test('the course has 12 units', () {
    expect(course.units, hasLength(12));
  });

  test('every listed lesson loads and its own answers are accepted', () {
    expect(course.lessonIds, isNotEmpty);
    for (final id in course.lessonIds) {
      final lesson = Lesson.fromJson(_read('assets/content/en/lessons/$id.json'));
      expect(lesson.id, id);
      expect(lesson.words, isNotEmpty);
      for (final exercise in lesson.exercises) {
        final Object answer = switch (exercise) {
          ChoiceExercise() => exercise.answerIndex,
          FillBlankExercise() => exercise.answerIndex,
          MatchingExercise() => true,
          BuildSentenceExercise() => exercise.answer,
          TranslateExercise() => exercise.answers.first,
        };
        expect(exercise.check(answer), isTrue, reason: '$id/${exercise.id}');
        expect(exercise.correctAnswer('uk'), isNotEmpty, reason: '$id/${exercise.id}');
        expect(exercise.explanation.of('uk'), isNotEmpty, reason: '$id/${exercise.id}');
      }
    }
  });

  test('a wrong answer is rejected', () {
    final lesson = Lesson.fromJson(_read('assets/content/en/lessons/u06_l02.json'));
    final translate = lesson.exercises.whereType<TranslateExercise>().first;
    expect(translate.check('I want like a coffee with milk'), isFalse);
    final build = lesson.exercises.whereType<BuildSentenceExercise>().first;
    expect(build.check(['We', 'want', 'the', 'bill']), isFalse);
  });
}
