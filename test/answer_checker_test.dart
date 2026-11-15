import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/answer_checker.dart';

void main() {
  const answers = ['I would like a coffee with milk', "I'd like a coffee with milk"];

  test('case, spaces and final punctuation do not matter', () {
    expect(matchesAnyAnswer('  i would like a coffee   with milk. ', answers), isTrue);
    expect(matchesAnyAnswer('I WOULD LIKE A COFFEE WITH MILK!', answers), isTrue);
  });

  test('curly apostrophes are accepted', () {
    expect(matchesAnyAnswer('I’d like a coffee with milk', answers), isTrue);
  });

  test('commas are ignored', () {
    expect(matchesAnyAnswer('Tea without sugar please', ['Tea without sugar, please']), isTrue);
  });

  test('a wrong or empty answer is rejected', () {
    expect(matchesAnyAnswer('I want like a coffee with milk', answers), isFalse);
    expect(matchesAnyAnswer('   ', answers), isFalse);
  });
}
