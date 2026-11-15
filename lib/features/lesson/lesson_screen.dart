import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import 'exercise_views.dart';

/// One lesson: new words and the rule first, then the exercises, then a summary.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final DateTime _startedAt = DateTime.now();
  final Set<String> _missed = {};
  List<Exercise>? _queue;
  bool _showIntro = true;
  bool _finished = false;
  int _index = 0;
  int _firstTryCorrect = 0;
  Object? _answer;
  bool? _result;

  void _check(Exercise exercise) {
    final correct = exercise.check(_answer);
    setState(() {
      _result = correct;
      if (correct) {
        if (!_missed.contains(exercise.id)) _firstTryCorrect++;
      } else if (_missed.add(exercise.id)) {
        // A missed exercise comes back once more at the end of the lesson.
        _queue!.add(exercise);
      }
    });
  }

  Future<void> _next(Lesson lesson) async {
    if (_index + 1 < _queue!.length) {
      setState(() {
        _index++;
        _answer = null;
        _result = null;
      });
      return;
    }
    final seconds = DateTime.now().difference(_startedAt).inSeconds;
    await ref.read(progressProvider.notifier).completeLesson(lesson, seconds: seconds);
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(lessonProvider(widget.lessonId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Закрити урок',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: lesson.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => LoadErrorView(onRetry: () => ref.invalidate(lessonProvider(widget.lessonId))),
          data: (value) {
            _queue ??= [...value.exercises];
            if (_showIntro) {
              return _IntroView(lesson: value, onStart: () => setState(() => _showIntro = false));
            }
            if (_finished) {
              return _SummaryView(
                lesson: value,
                firstTryCorrect: _firstTryCorrect,
                total: value.exercises.length,
              );
            }
            return _exerciseBody(value);
          },
        ),
      ),
    );
  }

  Widget _exerciseBody(Lesson lesson) {
    final queue = _queue!;
    final exercise = queue[_index];
    final result = _result;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _index / queue.length,
              minHeight: 12,
              backgroundColor: AppColors.tint,
              color: AppColors.accent,
              semanticsLabel: 'Прогрес уроку',
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ExerciseView(
              key: ValueKey('${exercise.id}-$_index'),
              exercise: exercise,
              enabled: result == null,
              onChanged: (answer) => setState(() => _answer = answer),
            ),
          ),
        ),
        if (result == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: FilledButton(
              onPressed: _answer == null ? null : () => _check(exercise),
              child: const Text('Перевірити'),
            ),
          )
        else
          _Feedback(
            correct: result,
            correctAnswer: exercise.correctAnswer(explanationLanguage),
            explanation: exercise.explanation.of(explanationLanguage),
            onNext: () => _next(lesson),
          ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
    required this.onNext,
  });

  final bool correct;
  final String correctAnswer;
  final String explanation;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final foreground = correct ? AppColors.navy : AppColors.accentDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: correct ? AppColors.paleBlue : AppColors.tint,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: foreground),
              const SizedBox(width: 8),
              Text(
                correct ? 'Правильно!' : 'Є помилка',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: foreground),
              ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 10),
            const Text(
              'Правильна відповідь',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
            ),
            Text(correctAnswer, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'Чому так?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
            ),
            Text(explanation, style: const TextStyle(fontSize: 16, height: 1.4)),
          ],
          const SizedBox(height: 14),
          FilledButton(onPressed: onNext, child: const Text('Далі')),
        ],
      ),
    );
  }
}

class _IntroView extends ConsumerWidget {
  const _IntroView({required this.lesson, required this.onStart});

  final Lesson lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Text(
                lesson.title.of(explanationLanguage),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.15),
              ),
              const SizedBox(height: 6),
              Text(
                lesson.goal.of(explanationLanguage),
                style: const TextStyle(fontSize: 16, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              AppCard(
                color: AppColors.paleBlue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Правило уроку',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.navy),
                    ),
                    const SizedBox(height: 6),
                    Text(lesson.rule.of(explanationLanguage), style: const TextStyle(fontSize: 16, height: 1.45)),
                  ],
                ),
              ),
              if (lesson.words.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Нові слова', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
              ],
              for (final word in lesson.words)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${word.text}  ${word.ipa}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                word.translation.of(explanationLanguage),
                                style: const TextStyle(fontSize: 15, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: AppColors.accent),
                          tooltip: 'Прослухати ${word.text}',
                          onPressed: () => ref.read(ttsProvider).speak(word.text),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: FilledButton(onPressed: onStart, child: const Text('Почати вправи')),
        ),
      ],
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.lesson, required this.firstTryCorrect, required this.total});

  final Lesson lesson;
  final int firstTryCorrect;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Урок пройдено', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            lesson.title.of(explanationLanguage),
            style: const TextStyle(fontSize: 17, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          AppCard(
            color: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstTryCorrect з $total',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const Text(
                  'вправ правильно з першої спроби',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Text(
              lesson.words.isEmpty
                  ? 'Це був урок повторення: нових слів немає.'
                  : 'Нових слів у словнику: ${lesson.words.length}. Перше повторення вже доступне.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Готово')),
        ],
      ),
    );
  }
}
