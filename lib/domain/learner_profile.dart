import 'practice_topics.dart';

/// Answers of the first-launch quiz. Used only to personalise the app
/// (greeting, daily goal, order of practice topics, tips). It never changes
/// which lessons are open.
class LearnerProfile {
  const LearnerProfile({
    this.name = '',
    this.goals = const {},
    this.level = 'zero',
    this.interests = const {},
    this.dailyMinutes = 10,
    this.skipped = false,
  });

  final String name;
  final Set<String> goals;
  final String level;
  final Set<String> interests;
  final int dailyMinutes;

  /// The learner skipped the quiz: nothing is personalised, the plan card is hidden.
  final bool skipped;

  bool get hasPlan => !skipped;

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    Set<String> strings(Object? value) =>
        value is List ? {for (final e in value) e.toString()} : <String>{};
    final minutes = json['dailyMinutes'];
    final level = json['level'];
    return LearnerProfile(
      name: json['name'] is String ? json['name'] as String : '',
      goals: strings(json['goals']),
      level: level is String && levelLabels.containsKey(level) ? level : 'zero',
      interests: strings(json['interests']),
      dailyMinutes: minutes is int && dailyMinuteOptions.contains(minutes) ? minutes : 10,
      skipped: json['skipped'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'goals': goals.toList()..sort(),
        'level': level,
        'interests': interests.toList()..sort(),
        'dailyMinutes': dailyMinutes,
        'skipped': skipped,
      };
}

const Map<String, String> goalLabels = {
  'travel': 'Подорожі',
  'work': 'Робота й кар’єра',
  'study': 'Навчання й іспити',
  'people': 'Спілкування з друзями й родиною',
  'move': 'Переїзд за кордон',
  'fun': 'Для себе, із цікавості',
};

const Map<String, String> levelLabels = {
  'zero': 'Починаю з нуля',
  'words': 'Знаю кілька слів',
  'phrases': 'Можу скласти прості фрази',
  'confident': 'Багато розумію, хочу більше практики',
};

const List<int> dailyMinuteOptions = [5, 10, 15, 20];

String dailyAdvice(int minutes) {
  switch (minutes) {
    case 5:
      return 'Короткий щоденний ритм: повторення слів або один урок, коли є хвилина.';
    case 15:
      return 'Орієнтир: один урок і повторення слів у словнику.';
    case 20:
      return 'Орієнтир: урок, повторення слів і сесія практики з діалогами.';
    default:
      return 'Орієнтир: один урок на день і швидке повторення слів.';
  }
}

String levelAdvice(String level) {
  switch (level) {
    case 'words':
      return 'Ви вже знаєте кілька слів, тому перші розділи пройдуть швидко.';
    case 'phrases':
    case 'confident':
      return 'Перші розділи можуть здатися легкими, проходьте їх швидко. Уроки відкриваються по черзі; тест рівня додамо пізніше.';
    default:
      return 'Ви починаєте з нуля, тож рухайтеся по порядку: кожен урок готує до наступного.';
  }
}

/// Topics the learner picked come first; the order inside both groups is kept.
List<PracticeTopic> orderTopics(List<PracticeTopic> topics, Set<String> interests) {
  return [
    for (final t in topics) if (interests.contains(t.id)) t,
    for (final t in topics) if (!interests.contains(t.id)) t,
  ];
}
