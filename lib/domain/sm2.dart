/// Spaced repetition with the SM-2 algorithm.
///
/// Quality is 0–5. Below 3 the word is forgotten and starts again tomorrow.
/// From 3 up the gap grows: 1 day, 6 days, then the previous gap times the
/// easiness factor. The easiness factor is updated first and never drops
/// below 1.3.
class Sm2State {
  const Sm2State({
    required this.repetitions,
    required this.easiness,
    required this.intervalDays,
    required this.due,
  });

  /// A word seen for the first time: due straight away.
  factory Sm2State.initial(DateTime now) {
    return Sm2State(repetitions: 0, easiness: 2.5, intervalDays: 0, due: dateOnly(now));
  }

  factory Sm2State.fromJson(Map<String, dynamic> json) {
    return Sm2State(
      repetitions: json['r'] as int,
      easiness: (json['e'] as num).toDouble(),
      intervalDays: json['i'] as int,
      due: dateOnly(DateTime.parse(json['d'] as String)),
    );
  }

  final int repetitions;
  final double easiness;
  final int intervalDays;
  final DateTime due;

  Map<String, dynamic> toJson() => {
        'r': repetitions,
        'e': easiness,
        'i': intervalDays,
        'd': dayKey(due),
      };

  bool isDue(DateTime now) => !due.isAfter(dateOnly(now));
}

const double minEasiness = 1.3;

Sm2State sm2Review(Sm2State state, int quality, DateTime now) {
  final q = quality.clamp(0, 5);
  final delta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
  var easiness = state.easiness + delta;
  if (easiness < minEasiness) easiness = minEasiness;

  int repetitions;
  int interval;
  if (q < 3) {
    repetitions = 0;
    interval = 1;
  } else {
    if (state.repetitions == 0) {
      interval = 1;
    } else if (state.repetitions == 1) {
      interval = 6;
    } else {
      interval = (state.intervalDays * easiness).round();
    }
    repetitions = state.repetitions + 1;
  }

  return Sm2State(
    repetitions: repetitions,
    easiness: easiness,
    intervalDays: interval,
    due: dateOnly(now).add(Duration(days: interval)),
  );
}

DateTime dateOnly(DateTime value) => DateTime.utc(value.year, value.month, value.day);

String dayKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
