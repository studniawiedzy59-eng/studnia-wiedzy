import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/my_words.dart';

MyWord _word(String id, String text, {String translation = '', String category = '', bool learned = false}) {
  return MyWord(
    id: id,
    text: text,
    createdAt: DateTime.utc(2026, 11, 16),
    translation: translation,
    category: category,
    learned: learned,
  );
}

void main() {
  final words = [
    _word('1', 'coffee', translation: 'кава', category: 'Їжа'),
    _word('2', 'Thank you', translation: 'дякую'),
    _word('3', 'bill', translation: 'рахунок', category: 'Їжа', learned: true),
    _word('4', 'ticket', translation: 'квиток', category: 'подорожі'),
  ];

  test('a word with only the English text can be saved and read back', () {
    final restored = decodeMyWords(encodeMyWords([_word('9', 'apple')]));
    expect(restored.single.text, 'apple');
    expect(restored.single.translation, '');
    expect(restored.single.learned, isFalse);
  });

  test('all fields survive saving and loading', () {
    final full = _word('5', 'menu', translation: 'меню', category: 'Їжа', learned: true)
        .copyWith(ipa: '/ˈmenjuː/', example: 'The menu, please.', exampleTranslation: 'Меню, будь ласка.');
    final restored = decodeMyWords(encodeMyWords([full])).single;
    expect(restored.toJson(), full.toJson());
  });

  test('duplicates are found regardless of case and punctuation', () {
    expect(findDuplicate(words, ' thank you! ')?.id, '2');
    expect(findDuplicate(words, 'COFFEE')?.id, '1');
    expect(findDuplicate(words, 'tea'), isNull);
    expect(findDuplicate(words, ''), isNull);
  });

  test('a word being edited is not its own duplicate', () {
    expect(findDuplicate(words, 'coffee', exceptId: '1'), isNull);
  });

  test('categories are unique and sorted', () {
    expect(categoriesOf(words), ['подорожі', 'Їжа']);
  });

  test('search looks in the word and in the translation', () {
    expect(filterMyWords(words, query: 'cof').map((w) => w.id), ['1']);
    expect(filterMyWords(words, query: 'квит').map((w) => w.id), ['4']);
    expect(filterMyWords(words, query: 'zzz'), isEmpty);
  });

  test('filters by category and hides learned words, sorted by text', () {
    expect(filterMyWords(words, category: 'Їжа').map((w) => w.text), ['bill', 'coffee']);
    expect(filterMyWords(words, category: 'Їжа', hideLearned: true).map((w) => w.text), ['coffee']);
    expect(filterMyWords(words).map((w) => w.text), ['bill', 'coffee', 'Thank you', 'ticket']);
  });
}
