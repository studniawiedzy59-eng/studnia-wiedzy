import 'models.dart';

/// One theme of the Practice tab: its card and the units whose dialogue scenes belong to it.
class PracticeTopic {
  const PracticeTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.units,
  });

  final String id;
  final String title;
  final String subtitle;
  final String image;

  /// Unit numbers, as in the lesson ids: `u02_l06` belongs to unit 2.
  final List<int> units;

  /// Real photo downloaded at build time (see tools/fetch_photos.py).
  String get photo => 'assets/images/photo_$id.jpg';

  bool owns(String lessonId) {
    final match = RegExp(r'^u(\d+)_').firstMatch(lessonId);
    if (match == null) return false;
    return units.contains(int.parse(match.group(1)!));
  }
}

const List<PracticeTopic> practiceTopics = [
  PracticeTopic(
    id: 'people',
    title: 'Знайомство і сім’я',
    subtitle: 'Привітання, розповідь про себе',
    image: 'assets/images/topic_people.png',
    units: [1, 3, 15, 40, 41, 42],
  ),
  PracticeTopic(
    id: 'cafe',
    title: 'Кафе й ресторан',
    subtitle: 'Замовити їжу й напої',
    image: 'assets/images/topic_cafe.png',
    units: [2, 10, 28, 53],
  ),
  PracticeTopic(
    id: 'shop',
    title: 'Магазин і гроші',
    subtitle: 'Ціни, одяг, покупки',
    image: 'assets/images/topic_shop.png',
    units: [11, 29, 54, 55, 56],
  ),
  PracticeTopic(
    id: 'travel',
    title: 'Подорожі',
    subtitle: 'Вокзал, аеропорт, готель',
    image: 'assets/images/topic_travel.png',
    units: [24, 25, 26, 27, 66, 73],
  ),
  PracticeTopic(
    id: 'city',
    title: 'Місто й дорога',
    subtitle: 'Як пройти, мій район',
    image: 'assets/images/topic_city.png',
    units: [22, 23, 59, 60],
  ),
  PracticeTopic(
    id: 'health',
    title: 'Здоров’я',
    subtitle: 'Лікар, аптека, самопочуття',
    image: 'assets/images/topic_health.png',
    units: [32, 33, 72],
  ),
  PracticeTopic(
    id: 'work',
    title: 'Робота й зв’язок',
    subtitle: 'Професії, телефон, листи',
    image: 'assets/images/topic_work.png',
    units: [14, 34, 47, 76, 77],
  ),
  PracticeTopic(
    id: 'home',
    title: 'Дім і побут',
    subtitle: 'Квартира, меблі, день',
    image: 'assets/images/topic_home.png',
    units: [19, 57, 58],
  ),
  PracticeTopic(
    id: 'holiday',
    title: 'Дозвілля і свята',
    subtitle: 'Хобі, запрошення, свята',
    image: 'assets/images/topic_holiday.png',
    units: [17, 18, 35, 36, 49, 62, 71],
  ),
];

/// The dialogue scenes of [topic], taken from the lessons that are already in the course.
List<DialogueExercise> scenesForTopic(PracticeTopic topic, Iterable<Lesson> lessons) {
  return [
    for (final lesson in lessons)
      if (topic.owns(lesson.id))
        for (final exercise in lesson.exercises)
          if (exercise is DialogueExercise) exercise,
  ];
}
