import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/practice_topics.dart';
import '../../state/providers.dart';
import '../lesson/exercise_views.dart';

/// Practice: real-life conversations, grouped by theme. Nothing here changes
/// which lessons are open; it is extra speaking and listening practice.
class PracticeTab extends ConsumerWidget {
  const PracticeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(allLessonsProvider);
    if (lessons.hasError) {
      return LoadErrorView(onRetry: () => ref.invalidate(allLessonsProvider));
    }
    if (!lessons.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final all = lessons.value!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      children: [
        const Text('Практика', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text(
          'Живі розмови з життя. Обирайте тему й відповідайте так, як сказав би носій.',
          style: TextStyle(fontSize: 15, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        const AppCard(
          color: AppColors.paleBlue,
          child: Text(
            'Вільна розмова з AI-репетитором і голосові відповіді з’являться в наступній версії.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < practiceTopics.length; i++) ...[
          _TopicCard(
            topic: practiceTopics[i],
            sceneCount: scenesForTopic(practiceTopics[i], all).length,
            onTap: () {
              final scenes = scenesForTopic(practiceTopics[i], all);
              if (scenes.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeSessionScreen(topic: practiceTopics[i], scenes: scenes),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.sceneCount, required this.onTap});

  final PracticeTopic topic;
  final int sceneCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: Semantics(
        button: true,
        label: '${topic.title}, сцен: $sceneCount',
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: sceneCount == 0 ? null : onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 600 / 340,
                  child: Image.asset(
                    topic.photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      topic.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.tint),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(topic.subtitle, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Text(
                        sceneCount == 0 ? 'скоро' : '$sceneCount сцен',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A session of up to eight scenes of one theme, in a fresh random order.
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key, required this.topic, required this.scenes});

  final PracticeTopic topic;
  final List<DialogueExercise> scenes;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  late final List<DialogueExercise> _queue = _pick();
  int _index = 0;
  int _correct = 0;
  Object? _answer;
  bool? _result;

  List<DialogueExercise> _pick() {
    final items = [...widget.scenes]..shuffle(Random());
    return items.take(8).toList();
  }

  void _check(DialogueExercise scene) {
    final ok = scene.check(_answer);
    setState(() {
      _result = ok;
      if (ok) _correct++;
    });
  }

  void _next() {
    setState(() {
      _index++;
      _answer = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _index >= _queue.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Закрити',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: finished ? _summary(context) : _scene(_queue[_index])),
    );
  }

  Widget _scene(DialogueExercise scene) {
    final result = _result;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _index / _queue.length,
              minHeight: 12,
              backgroundColor: AppColors.tint,
              color: AppColors.accent,
              semanticsLabel: 'Прогрес практики',
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: FadeSlideIn(
              key: ValueKey('scene-$_index'),
              child: AnswerFeedbackAnimation(
                result: result,
                child: ExerciseView(
                  exercise: scene,
                  enabled: result == null,
                  onChanged: (answer) => setState(() => _answer = answer),
                ),
              ),
            ),
          ),
        ),
        if (result == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: FilledButton(
              onPressed: _answer == null ? null : () => _check(scene),
              child: const Text('Перевірити'),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
              color: result ? AppColors.paleBlue : AppColors.tint,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result ? 'Правильно!' : 'Є помилка',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: result ? AppColors.navy : AppColors.accentDark,
                  ),
                ),
                if (!result) ...[
                  const SizedBox(height: 8),
                  Text(
                    scene.correctAnswer(explanationLanguage),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
                const SizedBox(height: 6),
                Text(scene.explanation.of(explanationLanguage), style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _next,
                  child: Text(_index + 1 < _queue.length ? 'Далі' : 'Завершити'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble, size: 64, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            '$_correct з ${_queue.length}',
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'правильних відповідей з першого разу',
            style: TextStyle(fontSize: 16, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('До тем'),
          ),
        ],
      ),
    );
  }
}
