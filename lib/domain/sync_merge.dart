import 'my_words.dart';
import 'progress.dart';
import 'sm2.dart';

/// Joins the progress kept on this phone with the copy from the server.
/// Used when someone signs in on a phone that already has learning data, so
/// neither side loses anything. Rules:
/// - finished lessons: both sets together;
/// - each word: the state that has more successful repetitions wins (the
///   later due date if equal), because states carry no timestamp;
/// - minutes per day: the larger number (adding would double-count after
///   repeated syncs);
/// - streak: taken from the side that was active more recently.
Progress mergeProgress(Progress a, Progress b) {
  final words = <String, Sm2State>{...a.words};
  for (final entry in b.words.entries) {
    final mine = words[entry.key];
    if (mine == null || _newer(entry.value, mine)) words[entry.key] = entry.value;
  }
  final seconds = <String, int>{...a.secondsByDay};
  for (final entry in b.secondsByDay.entries) {
    final mine = seconds[entry.key] ?? 0;
    seconds[entry.key] = entry.value > mine ? entry.value : mine;
  }
  final aDay = a.lastActiveDay ?? '';
  final bDay = b.lastActiveDay ?? '';
  final Progress streakSource;
  if (aDay == bDay) {
    streakSource = a.streak >= b.streak ? a : b;
  } else {
    streakSource = aDay.compareTo(bDay) > 0 ? a : b;
  }
  return Progress(
    completedLessons: {...a.completedLessons, ...b.completedLessons},
    words: words,
    streak: streakSource.streak,
    lastActiveDay: streakSource.lastActiveDay,
    secondsByDay: seconds,
  );
}

bool _newer(Sm2State candidate, Sm2State current) {
  if (candidate.repetitions != current.repetitions) {
    return candidate.repetitions > current.repetitions;
  }
  return candidate.due.isAfter(current.due);
}

/// Own words from both sides; for a word present on both, [local] wins.
List<MyWord> mergeMyWords(List<MyWord> local, List<MyWord> remote) {
  final ids = {for (final w in local) w.id};
  return [...local, for (final w in remote) if (!ids.contains(w.id)) w];
}
