import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../domain/flashcards.dart';
import '../../domain/models.dart';
import '../../domain/progress.dart';
import '../../state/providers.dart';
import '../words/words_screen.dart' show indexWords;
import 'flip_card.dart';

/// Flashcards over learned lesson words and the learner's own words.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  FlashFilter _filter = FlashFilter.all;
  late FlashDeck _deck;
  // Changes after every answer so the next card starts on its front side.
  int _step = 0;

  List<FlashCard> _cardsFor(FlashFilter filter) {
    final lessons = ref.read(allLessonsProvider).value ?? const <Lesson>[];
    final progress = ref.read(progressProvider).value;
    return buildFlashCards(
      lessonWords: indexWords(lessons),
      progress: progress ?? const Progress.empty(),
      myWords: ref.read(myWordsProvider).value ?? const [],
      filter: filter,
      now: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    _deck = FlashDeck(_cardsFor(_filter));
  }

  void _setFilter(FlashFilter filter) {
    setState(() {
      _filter = filter;
      _deck = FlashDeck(_cardsFor(filter));
      _step++;
    });
  }

  Future<void> _know(FlashCard card) async {
    setState(() {
      _deck.know();
      _step++;
    });
    if (card.myWordId != null) {
      final mine = (ref.read(myWordsProvider).value ?? const []).where((w) => w.id == card.myWordId);
      if (mine.isNotEmpty) await ref.read(myWordsProvider.notifier).replace(mine.first.copyWith(learned: true));
    } else if (card.wordKey != null) {
      // "I know it" counts as an easy review, so the next review moves further away.
      await ref.read(progressProvider.notifier).reviewWord(card.wordKey!, 5);
    }
  }

  void _again() => setState(() {
        _deck.again();
        _step++;
      });

  @override
  Widget build(BuildContext context) {
    final card = _deck.current;
    return Scaffold(
      appBar: AppBar(title: const Text('Флешкартки')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final item in const [
                    (FlashFilter.all, 'Усі'),
                    (FlashFilter.mine, 'Мої слова'),
                    (FlashFilter.due, 'На повторення'),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: _filter == item.$1,
                      selectedColor: AppColors.tint,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                      onSelected: (_) => _setFilter(item.$1),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (_deck.total > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _deck.progress),
                    duration: reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      backgroundColor: AppColors.tint,
                      color: AppColors.accent,
                      semanticsLabel: 'Прогрес колоди',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Вивчено ${_deck.known} з ${_deck.total}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: card == null ? _EmptyState(filter: _filter, finished: _deck.total > 0, onRestart: () => _setFilter(_filter)) : _cardArea(card),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardArea(FlashCard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FadeSlideIn(
            key: ValueKey('card-${card.id}-$_step'),
            child: FlipCard(
              front: _CardFace(
                color: AppColors.card,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                    ),
                    if (card.ipa.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(card.ipa, style: const TextStyle(fontSize: 20, color: AppColors.muted)),
                    ],
                    const SizedBox(height: 20),
                    IconButton.filled(
                      iconSize: 30,
                      icon: const Icon(Icons.volume_up),
                      tooltip: 'Прослухати вимову',
                      onPressed: () => ref.read(ttsProvider).speak(card.text),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Торкніться картки, щоб перевернути',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              back: _CardFace(
                color: AppColors.tint,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.translation.isEmpty ? 'Переклад не додано' : card.translation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: card.translation.isEmpty ? 20 : 34,
                        fontWeight: FontWeight.w900,
                        color: card.translation.isEmpty ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                    if (card.example.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(
                        card.example,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      if (card.exampleTranslation.isNotEmpty)
                        Text(
                          card.exampleTranslation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: AppColors.muted),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          key: ValueKey('buttons-$_step'),
          delay: const Duration(milliseconds: 120),
          child: Row(
            children: [
              Expanded(
                child: Pressable(
                  child: FilledButton.tonal(onPressed: _again, child: const Text('Повторити ще')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Pressable(child: FilledButton(onPressed: () => _know(card), child: const Text('Знаю'))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.finished, required this.onRestart});

  final FlashFilter filter;
  final bool finished;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String text;
    if (finished) {
      title = 'Колоду пройдено';
      text = 'Усі картки позначено як відомі. Можна почати знову.';
    } else {
      title = 'Карток поки немає';
      text = switch (filter) {
        FlashFilter.mine => 'Додайте власні слова в розділі «Мій словник».',
        FlashFilter.due => 'На сьогодні повторювати нічого. Зазирніть пізніше.',
        FlashFilter.all => 'Пройдіть перший урок або додайте власні слова.',
      };
    }
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontSize: 16, height: 1.4), textAlign: TextAlign.center),
            if (finished) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRestart, child: const Text('Почати знову')),
            ],
          ],
        ),
      ),
    );
  }
}
