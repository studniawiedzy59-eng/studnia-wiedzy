import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/my_words.dart';
import 'package:movira/domain/progress.dart';
import 'package:movira/domain/sm2.dart';
import 'package:movira/domain/sync_merge.dart';

Sm2State _state(int repetitions, String due) => Sm2State(
      repetitions: repetitions,
      easiness: 2.5,
      intervalDays: 1,
      due: DateTime.parse(due),
    );

Progress _progress({
  Set<String> lessons = const {},
  Map<String, Sm2State> words = const {},
  int streak = 0,
  String? day,
  Map<String, int> seconds = const {},
}) =>
    Progress(completedLessons: lessons, words: words, streak: streak, lastActiveDay: day, secondsByDay: seconds);

void main() {
  test('finished lessons from both sides are kept', () {
    final merged = mergeProgress(_progress(lessons: {'u01_l01'}), _progress(lessons: {'u01_l01', 'u01_l02'}));
    expect(merged.completedLessons, {'u01_l01', 'u01_l02'});
  });

  test('a word keeps the state with more repetitions and new words are added', () {
    final a = _progress(words: {'w1': _state(2, '2026-12-01'), 'w2': _state(0, '2026-11-26')});
    final b = _progress(words: {'w1': _state(4, '2026-12-10'), 'w3': _state(1, '2026-11-27')});
    final merged = mergeProgress(a, b);
    expect(merged.words['w1']!.repetitions, 4);
    expect(merged.words.keys.toSet(), {'w1', 'w2', 'w3'});
  });

  test('minutes per day take the larger value, never the sum', () {
    final merged = mergeProgress(
      _progress(seconds: {'2026-11-26': 300, '2026-11-25': 60}),
      _progress(seconds: {'2026-11-26': 120}),
    );
    expect(merged.secondsByDay['2026-11-26'], 300);
    expect(merged.secondsByDay['2026-11-25'], 60);
  });

  test('the streak comes from the side active more recently', () {
    final merged = mergeProgress(
      _progress(streak: 9, day: '2026-11-20'),
      _progress(streak: 3, day: '2026-11-26'),
    );
    expect(merged.streak, 3);
    expect(merged.lastActiveDay, '2026-11-26');
  });

  test('merging with an empty progress changes nothing', () {
    final a = _progress(lessons: {'u01_l01'}, streak: 2, day: '2026-11-26', seconds: {'2026-11-26': 90});
    final merged = mergeProgress(a, const Progress.empty());
    expect(merged.toJson(), a.toJson());
  });

  test('own words: local wins for the same id, remote-only words are added', () {
    final local = [MyWord(id: 'a', text: 'cat', createdAt: DateTime(2026, 11, 1), translation: 'кіт')];
    final remote = [
      MyWord(id: 'a', text: 'cat', createdAt: DateTime(2026, 11, 1), translation: 'інший'),
      MyWord(id: 'b', text: 'dog', createdAt: DateTime(2026, 11, 2)),
    ];
    final merged = mergeMyWords(local, remote);
    expect(merged.map((w) => w.id), ['a', 'b']);
    expect(merged.first.translation, 'кіт');
  });
}
