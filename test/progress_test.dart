import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/progress.dart';

void main() {
  final monday = DateTime.utc(2026, 11, 16, 10);

  test('finishing a lesson adds its words for review today', () {
    final progress = const Progress.empty().withLessonCompleted('u01_l01', ['hello', 'name'], monday);
    expect(progress.completedLessons, {'u01_l01'});
    expect(progress.dueWordKeys(monday), ['u01_l01/hello', 'u01_l01/name']);
  });

  test('repeating a lesson does not reset reviewed words', () {
    var progress = const Progress.empty().withLessonCompleted('u01_l01', ['hello'], monday);
    progress = progress.withWordReviewed('u01_l01/hello', 5, monday);
    progress = progress.withLessonCompleted('u01_l01', ['hello'], monday);
    expect(progress.words['u01_l01/hello']!.repetitions, 1);
    expect(progress.dueWordKeys(monday), isEmpty);
  });

  test('the streak grows day by day and breaks after a missed day', () {
    var progress = const Progress.empty().withActivity(monday, seconds: 120);
    expect(progress.currentStreak(monday), 1);
    expect(progress.minutesOn(monday), 2);

    final tuesday = monday.add(const Duration(days: 1));
    progress = progress.withActivity(tuesday);
    expect(progress.currentStreak(tuesday), 2);

    final friday = monday.add(const Duration(days: 4));
    expect(progress.currentStreak(friday), 0);
    progress = progress.withActivity(friday);
    expect(progress.currentStreak(friday), 1);
  });

  test('lessons open one after another', () {
    const order = ['l1', 'l2', 'l3'];
    expect(isLessonUnlocked(order, {}, 'l1'), isTrue);
    expect(isLessonUnlocked(order, {}, 'l2'), isFalse);
    expect(isLessonUnlocked(order, {'l1'}, 'l2'), isTrue);
    expect(isLessonUnlocked(order, {'l1'}, 'l3'), isFalse);
    expect(isLessonUnlocked(order, {'l1', 'l2'}, 'l3'), isTrue);
    expect(isLessonUnlocked(order, {'l3'}, 'l3'), isTrue);
    expect(isLessonUnlocked(order, {'l1'}, 'missing'), isFalse);
  });

  test('progress survives saving and loading', () {
    final progress = const Progress.empty()
        .withLessonCompleted('u01_l01', ['hello'], monday)
        .withActivity(monday, seconds: 90);
    final restored = Progress.fromJson(jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>);
    expect(restored.completedLessons, progress.completedLessons);
    expect(restored.words.keys, progress.words.keys);
    expect(restored.streak, 1);
    expect(restored.secondsByDay, progress.secondsByDay);
  });
}
