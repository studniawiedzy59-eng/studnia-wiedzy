import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/models.dart';

Map<String, dynamic> _read(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  final course = Course.fromJson(_read('assets/content/en/course.json'));

  test('every level from A0 to C2 has 40 units', () {
    expect(course.units, hasLength(280));
    for (final level in ['A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(course.units.where((unit) => unit.cefr == level), hasLength(40), reason: level);
    }
    expect(course.units.map((unit) => unit.id).toSet(), hasLength(280));
  });

  test('every listed lesson loads and its own answers are accepted', () {
    expect(course.lessonIds, isNotEmpty);
    for (final id in course.lessonIds) {
      final lesson = Lesson.fromJson(_read('assets/content/en/lessons/$id.json'));
      expect(lesson.id, id);
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

  test('the first unit has six lessons and ends with a review', () {
    final unit = course.units.first;
    expect(unit.lessonIds, hasLength(6));
    final review = Lesson.fromJson(_read('assets/content/en/lessons/${unit.lessonIds.last}.json'));
    expect(review.words, isEmpty);
  });

  test('a wrong answer is rejected', () {
    final lesson = Lesson.fromJson(_read('assets/content/en/lessons/u01_l02.json'));
    final translate = lesson.exercises.whereType<TranslateExercise>().first;
    expect(translate.check('Nice meet you'), isFalse);
    final build = lesson.exercises.whereType<BuildSentenceExercise>().first;
    expect(build.check(['My', 'name', 'Tom']), isFalse);
  });
}
