import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/practice_topics.dart';
import 'package:movira/domain/unit_photos.dart';

void main() {
  test('every A0 and A1 unit has a photo topic that exists', () {
    final ids = practiceTopics.map((t) => t.id).toSet();
    for (var unit = 1; unit <= 80; unit++) {
      final topic = photoTopicForUnit(unit);
      expect(topic, isNotNull, reason: 'unit $unit has no photo topic');
      expect(ids.contains(topic), isTrue, reason: 'unit $unit: unknown topic $topic');
    }
  });

  test('units that are not ready have no photo', () {
    expect(photoTopicForUnit(81), isNull);
  });
}
