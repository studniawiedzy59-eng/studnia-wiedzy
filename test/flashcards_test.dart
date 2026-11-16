import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/flashcards.dart';
import 'package:movira/domain/models.dart';
import 'package:movira/domain/my_words.dart';
import 'package:movira/domain/progress.dart';

Word _word(String id, String text, String uk) => Word(
      id: id,
      text: text,
      ipa: '/$text/',
      pos: 'noun',
      translation: L10nText({'uk': uk}),
      example: 'A $text.',
      exampleTranslation: L10nText({'uk': 'Приклад: $uk.'}),
    );

MyWord _mine(String id, String text, {bool learned = false, int day = 1}) => MyWord(
      id: id,
      text: text,
      createdAt: DateTime.utc(2026, 11, day),
      translation: 'мій $text',
      learned: learned,
    );

void main() {
  final now = DateTime.utc(2026, 11, 16, 12);
  final words = {
    'u01_l01/cat': _word('cat', 'cat', 'кіт'),
    'u01_l01/dog': _word('dog', 'dog', 'пес'),
    'u02_l01/sun': _word('sun', 'sun', 'сонце'),
  };
  // Cat and dog were learned; the sun lesson is not finished yet.
  final progress = const Progress.empty().withLessonCompleted('u01_l01', ['cat', 'dog'], now);
  final mine = [_mine('b', 'bike', day: 2), _mine('a', 'apple', learned: true, day: 1)];

  List<String> ids(FlashFilter filter, {Progress? p}) => buildFlashCards(
        lessonWords: words,
        progress: p ?? progress,
        myWords: mine,
        filter: filter,
        now: now,
      ).map((c) => c.id).toList();

  test('"all" has learned lesson words, then own words in the order they were added', () {
    expect(ids(FlashFilter.all), ['lesson:u01_l01/cat', 'lesson:u01_l01/dog', 'my:a', 'my:b']);
  });

  test('"mine" has only own words', () {
    expect(ids(FlashFilter.mine), ['my:a', 'my:b']);
  });

  test('"due" has words due today and own words that are not learned yet', () {
    expect(ids(FlashFilter.due), ['lesson:u01_l01/cat', 'lesson:u01_l01/dog', 'my:b']);
    final reviewed = progress.withWordReviewed('u01_l01/cat', 5, now);
    expect(ids(FlashFilter.due, p: reviewed), ['lesson:u01_l01/dog', 'my:b']);
  });

  test('a card carries the word, transcription, translation and example', () {
    final card = buildFlashCards(
      lessonWords: words,
      progress: progress,
      myWords: const [],
      filter: FlashFilter.all,
      now: now,
    ).first;
    expect(card.text, 'cat');
    expect(card.ipa, '/cat/');
    expect(card.translation, 'кіт');
    expect(card.example, 'A cat.');
    expect(card.exampleTranslation, 'Приклад: кіт.');
    expect(card.wordKey, 'u01_l01/cat');
    expect(card.isMine, isFalse);
  });

  test('"again" sends the card to the end, "know" removes it and moves the progress bar', () {
    final deck = FlashDeck(buildFlashCards(
      lessonWords: words,
      progress: progress,
      myWords: const [],
      filter: FlashFilter.all,
      now: now,
    ));
    expect(deck.total, 2);
    expect(deck.progress, 0);
    expect(deck.current!.text, 'cat');
    deck.again();
    expect(deck.current!.text, 'dog');
    expect(deck.remaining, 2);
    deck.know();
    expect(deck.known, 1);
    expect(deck.progress, 0.5);
    expect(deck.current!.text, 'cat');
    deck.know();
    expect(deck.isDone, isTrue);
    expect(deck.progress, 1);
    expect(deck.current, isNull);
    deck.know();
    deck.again();
    expect(deck.known, 2);
  });

  test('an empty deck is done at once with zero progress', () {
    final deck = FlashDeck(const []);
    expect(deck.isDone, isTrue);
    expect(deck.progress, 0);
  });
}
