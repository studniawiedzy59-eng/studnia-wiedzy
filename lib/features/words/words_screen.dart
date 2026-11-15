import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Words of every loaded lesson, keyed the same way as in the saved progress.
Map<String, Word> indexWords(List<Lesson> lessons) {
  return {
    for (final lesson in lessons)
      for (final word in lesson.words) '${lesson.id}/${word.id}': word,
  };
}

/// The learner's dictionary: learned words and the review button.
class WordsTab extends ConsumerWidget {
  const WordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(allLessonsProvider);
    final progress = ref.watch(progressProvider);
    if (lessons.hasError || progress.hasError) {
      return LoadErrorView(onRetry: () {
        ref.invalidate(allLessonsProvider);
        ref.invalidate(progressProvider);
      });
    }
    if (!lessons.hasValue || !progress.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final words = indexWords(lessons.value!);
    final state = progress.value!;
    final now = DateTime.now();
    final known = [for (final key in state.words.keys) if (words.containsKey(key)) key]..sort();
    final due = [for (final key in state.dueWordKeys(now)) if (words.containsKey(key)) key];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Словник', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        if (known.isEmpty)
          const AppCard(
            child: Text(
              'Тут з’являться слова з пройдених уроків. Пройдіть перший урок, щоб почати.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          )
        else ...[
          AppCard(
            color: due.isEmpty ? AppColors.paleBlue : AppColors.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  due.isEmpty ? 'На сьогодні все повторено' : 'Слів на повторення: ${due.length}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: due.isEmpty ? AppColors.navy : Colors.white,
                  ),
                ),
                if (due.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.accentDark,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => ReviewScreen(wordKeys: due, words: words)),
                    ),
                    child: const Text('Повторити'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final key in known)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            words[key]!.text,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            words[key]!.translation.of(explanationLanguage),
                            style: const TextStyle(fontSize: 14, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (due.contains(key))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Сьогодні',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accentDark),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// A review session: one word at a time, graded by the learner.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.wordKeys, required this.words});

  final List<String> wordKeys;
  final Map<String, Word> words;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _index = 0;
  bool _revealed = false;
  DateTime _shownAt = DateTime.now();

  Future<void> _rate(int quality) async {
    final seconds = DateTime.now().difference(_shownAt).inSeconds;
    await ref
        .read(progressProvider.notifier)
        .reviewWord(widget.wordKeys[_index], quality, seconds: seconds);
    if (!mounted) return;
    if (_index + 1 >= widget.wordKeys.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
      _shownAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.words[widget.wordKeys[_index]]!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Закрити повторення',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${_index + 1} з ${widget.wordKeys.length}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(22),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word.text,
                                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    word.ipa,
                                    style: const TextStyle(fontSize: 18, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              iconSize: 28,
                              icon: const Icon(Icons.volume_up),
                              tooltip: 'Прослухати вимову',
                              onPressed: () => ref.read(ttsProvider).speak(word.text),
                            ),
                          ],
                        ),
                        if (_revealed) ...[
                          const Divider(height: 36),
                          const Text(
                            'Переклад',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
                          ),
                          Text(
                            word.translation.of(explanationLanguage),
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 16),
                          Text(word.example, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          Text(
                            word.exampleTranslation.of(explanationLanguage),
                            style: const TextStyle(fontSize: 15, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_revealed)
                FilledButton(
                  onPressed: () => setState(() => _revealed = true),
                  child: const Text('Показати переклад'),
                )
              else ...[
                const Text(
                  'Наскільки добре ви пам’ятали це слово?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _RateButton(label: 'Не пам’ятаю', onTap: () => _rate(1))),
                    const SizedBox(width: 10),
                    Expanded(child: _RateButton(label: 'Важко', onTap: () => _rate(3))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _RateButton(label: 'Добре', onTap: () => _rate(4))),
                    const SizedBox(width: 10),
                    Expanded(child: _RateButton(label: 'Легко', onTap: () => _rate(5))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
