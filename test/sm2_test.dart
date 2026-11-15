import 'package:flutter_test/flutter_test.dart';
import 'package:movira/domain/sm2.dart';

void main() {
  final day = DateTime.utc(2026, 11, 15);

  test('a new word is due straight away', () {
    final state = Sm2State.initial(day);
    expect(state.isDue(day), isTrue);
    expect(state.easiness, 2.5);
  });

  test('easy answers grow the gap: 1 day, 6 days, then times easiness', () {
    var state = sm2Review(Sm2State.initial(day), 5, day);
    expect(state.intervalDays, 1);
    expect(state.repetitions, 1);
    expect(state.easiness, closeTo(2.6, 1e-9));
    expect(state.due, DateTime.utc(2026, 11, 16));

    state = sm2Review(state, 5, day);
    expect(state.intervalDays, 6);
    expect(state.easiness, closeTo(2.7, 1e-9));

    state = sm2Review(state, 5, day);
    expect(state.intervalDays, 17); // round(6 * 2.8)
    expect(state.repetitions, 3);
  });

  test('a forgotten word starts again tomorrow and gets harder', () {
    var state = sm2Review(Sm2State.initial(day), 5, day);
    state = sm2Review(state, 5, day);
    state = sm2Review(state, 1, day);
    expect(state.repetitions, 0);
    expect(state.intervalDays, 1);
    expect(state.easiness, closeTo(2.7 - 0.54, 1e-9));
  });

  test('easiness never drops below 1.3', () {
    var state = Sm2State.initial(day);
    for (var i = 0; i < 20; i++) {
      state = sm2Review(state, 0, day);
    }
    expect(state.easiness, minEasiness);
  });

  test('a word is not due before its date and is due on it', () {
    final state = sm2Review(Sm2State.initial(day), 4, day);
    expect(state.isDue(day), isFalse);
    expect(state.isDue(day.add(const Duration(days: 1))), isTrue);
  });

  test('state survives saving and loading', () {
    final state = sm2Review(Sm2State.initial(day), 4, day);
    final restored = Sm2State.fromJson(state.toJson());
    expect(restored.repetitions, state.repetitions);
    expect(restored.intervalDays, state.intervalDays);
    expect(restored.easiness, state.easiness);
    expect(restored.due, state.due);
  });
}
