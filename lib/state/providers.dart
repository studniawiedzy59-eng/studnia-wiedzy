import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/content_repository.dart';
import '../data/my_words_repository.dart';
import '../data/progress_repository.dart';
import '../domain/models.dart';
import '../domain/my_words.dart';
import '../domain/progress.dart';

/// Language used for explanations. Ukrainian until the settings switch exists.
const String explanationLanguage = 'uk';

final contentRepositoryProvider = Provider<ContentRepository>((ref) => ContentRepository());

final progressRepositoryProvider = Provider<ProgressRepository>((ref) => ProgressRepository());

final courseProvider = FutureProvider<Course>((ref) {
  return ref.watch(contentRepositoryProvider).loadCourse();
});

final lessonProvider = FutureProvider.family<Lesson, String>((ref, lessonId) {
  return ref.watch(contentRepositoryProvider).loadLesson(lessonId);
});

/// Every lesson of the course, in course order.
final allLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final course = await ref.watch(courseProvider.future);
  final repository = ref.watch(contentRepositoryProvider);
  return [for (final id in course.lessonIds) await repository.loadLesson(id)];
});

final ttsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage('en-GB');
  tts.setSpeechRate(0.45);
  ref.onDispose(tts.stop);
  return tts;
});

final progressProvider = AsyncNotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);

class ProgressNotifier extends AsyncNotifier<Progress> {
  @override
  Future<Progress> build() => ref.read(progressRepositoryProvider).load();

  Progress get _current => state.value ?? const Progress.empty();

  Future<void> _set(Progress next) async {
    state = AsyncData(next);
    await ref.read(progressRepositoryProvider).save(next);
  }

  Future<void> completeLesson(Lesson lesson, {required int seconds}) {
    final now = DateTime.now();
    return _set(_current
        .withLessonCompleted(lesson.id, lesson.words.map((w) => w.id), now)
        .withActivity(now, seconds: seconds));
  }

  Future<void> reviewWord(String wordKey, int quality, {int seconds = 0}) {
    final now = DateTime.now();
    return _set(_current.withWordReviewed(wordKey, quality, now).withActivity(now, seconds: seconds));
  }

  Future<void> reset() async {
    await ref.read(progressRepositoryProvider).clear();
    state = const AsyncData(Progress.empty());
  }
}

final myWordsRepositoryProvider = Provider<MyWordsRepository>((ref) => MyWordsRepository());

/// The learner's own dictionary. Every change is saved to the device at once.
final myWordsProvider = AsyncNotifierProvider<MyWordsNotifier, List<MyWord>>(MyWordsNotifier.new);

class MyWordsNotifier extends AsyncNotifier<List<MyWord>> {
  @override
  Future<List<MyWord>> build() => ref.read(myWordsRepositoryProvider).load();

  Future<void> _change(List<MyWord> Function(List<MyWord> current) change) async {
    // Wait for the saved list first, so an early tap can never overwrite it.
    final next = change(await future);
    state = AsyncData(next);
    await ref.read(myWordsRepositoryProvider).save(next);
  }

  Future<void> add(MyWord word) => _change((current) => [...current, word]);

  Future<void> replace(MyWord word) {
    return _change((current) => [for (final item in current) item.id == word.id ? word : item]);
  }

  Future<void> remove(String id) {
    return _change((current) => [for (final item in current) if (item.id != id) item]);
  }
}
