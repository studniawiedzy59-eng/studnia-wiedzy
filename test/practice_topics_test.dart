import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/practice_topics.dart';

void main() {
  test('topics have unique ids and every unit belongs to one topic only', () {
    expect(practiceTopics.map((t) => t.id).toSet().length, practiceTopics.length);
    final seen = <int>{};
    for (final topic in practiceTopics) {
      for (final unit in topic.units) {
        expect(seen.add(unit), isTrue, reason: 'unit $unit is in two topics');
      }
    }
  });

  test('a topic owns the lessons of its units only', () {
    final cafe = practiceTopics.firstWhere((t) => t.id == 'cafe');
    expect(cafe.owns('u02_l06'), isTrue);
    expect(cafe.owns('u03_l01'), isFalse);
    expect(cafe.owns('bad'), isFalse);
  });
}
