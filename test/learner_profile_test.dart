import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/learner_profile.dart';
import 'package:movira/domain/practice_topics.dart';

void main() {
  test('profile survives a save and load', () {
    const original = LearnerProfile(
      name: 'Олена',
      goals: {'travel', 'work'},
      level: 'words',
      interests: {'cafe', 'shop'},
      dailyMinutes: 15,
    );
    final loaded = LearnerProfile.fromJson(original.toJson());
    expect(loaded.name, 'Олена');
    expect(loaded.goals, {'travel', 'work'});
    expect(loaded.level, 'words');
    expect(loaded.interests, {'cafe', 'shop'});
    expect(loaded.dailyMinutes, 15);
    expect(loaded.hasPlan, isTrue);
  });

  test('bad or missing saved values fall back to safe defaults', () {
    final loaded = LearnerProfile.fromJson({'level': 'nonsense', 'dailyMinutes': 7, 'goals': 5});
    expect(loaded.level, 'zero');
    expect(loaded.dailyMinutes, 10);
    expect(loaded.goals, isEmpty);
    expect(loaded.skipped, isFalse);
  });

  test('a skipped quiz has no plan', () {
    expect(const LearnerProfile(skipped: true).hasPlan, isFalse);
  });

  test('chosen topics come first and nothing is lost', () {
    final ordered = orderTopics(practiceTopics, {'health', 'cafe'});
    expect(ordered.take(2).map((t) => t.id).toList(), ['cafe', 'health']);
    expect(ordered.length, practiceTopics.length);
    expect(ordered.map((t) => t.id).toSet().length, practiceTopics.length);
  });

  test('every answer option has advice text', () {
    for (final m in dailyMinuteOptions) {
      expect(dailyAdvice(m), isNotEmpty);
    }
    for (final l in levelLabels.keys) {
      expect(levelAdvice(l), isNotEmpty);
    }
  });
}
