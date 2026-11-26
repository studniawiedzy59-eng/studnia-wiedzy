/// Which topic photo each unit card shows on the learning path.
/// Only decoration: it does not decide which dialogue scenes a unit gets
/// (that is `practiceTopics`).
const Map<String, List<int>> _photoUnits = {
  'people': [1, 3, 13, 15, 16, 21, 40, 41, 42, 43, 44, 63, 64, 65, 67],
  'cafe': [2, 10, 28, 53, 79],
  'shop': [5, 8, 11, 29, 51, 52, 54, 55, 56],
  'travel': [24, 25, 26, 27, 66, 73, 78],
  'city': [22, 23, 30, 59, 60, 61, 68, 69, 70],
  'health': [32, 33, 50, 72, 74],
  'work': [6, 7, 14, 34, 39, 47, 48, 75, 76, 77],
  'home': [4, 9, 12, 19, 20, 37, 38, 45, 46, 57, 58],
  'holiday': [17, 18, 31, 35, 36, 49, 62, 71, 80],
};

final Map<int, String> _photoByUnit = {
  for (final e in _photoUnits.entries)
    for (final unit in e.value) unit: e.key,
};

/// Topic id whose photo belongs on the card of unit [number] (1-based), or null.
String? photoTopicForUnit(int number) => _photoByUnit[number];

String photoAssetFor(String topicId) => 'assets/images/photo_$topicId.jpg';
String drawnAssetFor(String topicId) => 'assets/images/topic_$topicId.png';
