/// Makes a typed answer comparable: case, extra spaces, curly apostrophes and
/// punctuation do not count as mistakes.
String normalizeAnswer(String input) {
  var text = input.toLowerCase().trim();
  text = text.replaceAll(RegExp('[‘’ʼ`]'), "'");
  text = text.replaceAll(RegExp(r'[.,!?;:"]'), ' ');
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}

/// True when [input] equals one of the accepted [answers] after normalizing.
bool matchesAnyAnswer(String input, List<String> answers) {
  final typed = normalizeAnswer(input);
  if (typed.isEmpty) return false;
  return answers.any((answer) => normalizeAnswer(answer) == typed);
}
