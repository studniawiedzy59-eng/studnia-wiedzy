import 'sm2.dart';

/// Lessons open one after another: the first is always open, every other one
/// opens when the lesson before it is finished. A finished lesson stays open.
bool isLessonUnlocked(List<String> courseOrder, Set<String> completed, String lessonId) {
  final index = courseOrder.indexOf(lessonId);
  if (index < 0) return false;
  if (index == 0 || completed.contains(lessonId)) return true;
  return completed.contains(courseOrder[index - 1]);
}

/// Everything the app remembers about one learner. Stored on the device.
class Progress {
  const Progress({
    required this.completedLessons,
    required this.words,
    required this.streak,
    required this.lastActiveDay,
    required this.secondsByDay,
  });

  const Progress.empty()
      : completedLessons = const {},
        words = const {},
        streak = 0,
        lastActiveDay = null,
        secondsByDay = const {};

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      completedLessons: ((json['lessons'] as List?) ?? const []).map((e) => e.toString()).toSet(),
      words: ((json['words'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k.toString(), Sm2State.fromJson(Map<String, dynamic>.from(v as Map))),
      ),
      streak: (json['streak'] as int?) ?? 0,
      lastActiveDay: json['lastDay'] as String?,
      secondsByDay: ((json['seconds'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k.toString(), v as int),
      ),
    );
  }

  final Set<String> completedLessons;

  /// Review state per word, keyed by `lessonId/wordId`.
  final Map<String, Sm2State> words;
  final int streak;
  final String? lastActiveDay;
  final Map<String, int> secondsByDay;

  Map<String, dynamic> toJson() => {
        'lessons': completedLessons.toList()..sort(),
        'words': words.map((k, v) => MapEntry(k, v.toJson())),
        'streak': streak,
        'lastDay': lastActiveDay,
        'seconds': secondsByDay,
      };

  List<String> dueWordKeys(DateTime now) {
    return [
      for (final entry in words.entries)
        if (entry.value.isDue(now)) entry.key,
    ]..sort();
  }

  int minutesOn(DateTime day) => ((secondsByDay[dayKey(day)] ?? 0) / 60).round();

  /// The streak as it stands today: it is lost after a full day without study.
  int currentStreak(DateTime now) {
    if (lastActiveDay == null) return 0;
    final today = dayKey(now);
    final yesterday = dayKey(dateOnly(now).subtract(const Duration(days: 1)));
    return (lastActiveDay == today || lastActiveDay == yesterday) ? streak : 0;
  }

  Progress withActivity(DateTime now, {int seconds = 0}) {
    final today = dayKey(now);
    final yesterday = dayKey(dateOnly(now).subtract(const Duration(days: 1)));
    final int newStreak;
    if (lastActiveDay == today) {
      newStreak = streak;
    } else if (lastActiveDay == yesterday) {
      newStreak = streak + 1;
    } else {
      newStreak = 1;
    }
    return Progress(
      completedLessons: completedLessons,
      words: words,
      streak: newStreak,
      lastActiveDay: today,
      secondsByDay: {...secondsByDay, today: (secondsByDay[today] ?? 0) + seconds},
    );
  }

  Progress withLessonCompleted(String lessonId, Iterable<String> wordIds, DateTime now) {
    final updated = {...words};
    for (final wordId in wordIds) {
      updated.putIfAbsent('$lessonId/$wordId', () => Sm2State.initial(now));
    }
    return Progress(
      completedLessons: {...completedLessons, lessonId},
      words: updated,
      streak: streak,
      lastActiveDay: lastActiveDay,
      secondsByDay: secondsByDay,
    );
  }

  Progress withWordReviewed(String wordKey, int quality, DateTime now) {
    final current = words[wordKey];
    if (current == null) return this;
    return Progress(
      completedLessons: completedLessons,
      words: {...words, wordKey: sm2Review(current, quality, now)},
      streak: streak,
      lastActiveDay: lastActiveDay,
      secondsByDay: secondsByDay,
    );
  }
}
