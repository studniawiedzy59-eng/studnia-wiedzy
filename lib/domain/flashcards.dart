import 'models.dart';
import 'my_words.dart';
import 'progress.dart';

/// Which words go into the flashcard deck.
enum FlashFilter { all, mine, due }

/// One card: a word from a lesson or from the learner's own dictionary.
class FlashCard {
  const FlashCard({
    required this.id,
    required this.text,
    required this.ipa,
    required this.translation,
    required this.example,
    required this.exampleTranslation,
    this.wordKey,
    this.myWordId,
  });

  /// Unique in a deck: `lesson:<key>` or `my:<id>`.
  final String id;
  final String text;
  final String ipa;
  final String translation;
  final String example;
  final String exampleTranslation;

  /// Key in the saved progress (`lessonId/wordId`) for a lesson word.
  final String? wordKey;

  /// Id of the word in the personal dictionary, for the learner's own words.
  final String? myWordId;

  bool get isMine => myWordId != null;
}

/// Builds the cards for a filter.
/// - [FlashFilter.all]: every word from finished lessons and every own word.
/// - [FlashFilter.mine]: own words only.
/// - [FlashFilter.due]: lesson words due for review today and own words not yet marked as learned.
List<FlashCard> buildFlashCards({
  required Map<String, Word> lessonWords,
  required Progress progress,
  required List<MyWord> myWords,
  required FlashFilter filter,
  required DateTime now,
  String language = 'uk',
}) {
  final cards = <FlashCard>[];
  if (filter != FlashFilter.mine) {
    final keys = filter == FlashFilter.due
        ? progress.dueWordKeys(now).toSet()
        : progress.words.keys.toSet();
    // Keep the course order of the lessons.
    for (final entry in lessonWords.entries) {
      if (!keys.contains(entry.key)) continue;
      final word = entry.value;
      cards.add(FlashCard(
        id: 'lesson:${entry.key}',
        text: word.text,
        ipa: word.ipa,
        translation: word.translation.of(language),
        example: word.example,
        exampleTranslation: word.exampleTranslation.of(language),
        wordKey: entry.key,
      ));
    }
  }
  {
    final own = [...myWords]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final word in own) {
      if (filter == FlashFilter.due && word.learned) continue;
      cards.add(FlashCard(
        id: 'my:${word.id}',
        text: word.text,
        ipa: word.ipa,
        translation: word.translation,
        example: word.example,
        exampleTranslation: word.exampleTranslation,
        myWordId: word.id,
      ));
    }
  }
  return cards;
}

/// A session over a fixed set of cards. "Again" sends the card to the end of the
/// deck, "know" takes it out; the session ends when no card is left.
class FlashDeck {
  FlashDeck(List<FlashCard> cards)
      : total = cards.length,
        _queue = [...cards];

  final int total;
  final List<FlashCard> _queue;
  int _known = 0;
  int _again = 0;

  FlashCard? get current => _queue.isEmpty ? null : _queue.first;
  int get known => _known;
  int get againCount => _again;
  int get remaining => _queue.length;
  bool get isDone => _queue.isEmpty;
  double get progress => total == 0 ? 0 : _known / total;

  void again() {
    if (_queue.isEmpty) return;
    _again++;
    _queue.add(_queue.removeAt(0));
  }

  void know() {
    if (_queue.isEmpty) return;
    _queue.removeAt(0);
    _known++;
  }
}
