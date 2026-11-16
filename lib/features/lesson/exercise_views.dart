import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';

/// Display order for answer options, mixed anew each time an exercise is
/// shown, so the right answer is never in a predictable place.
List<int> mixedOrder(int length) => List<int>.generate(length, (i) => i)..shuffle(Random());

/// Called with the learner's current answer, or `null` when nothing is chosen.
typedef AnswerChanged = void Function(Object? answer);

/// Picks the right widget for an exercise.
class ExerciseView extends StatelessWidget {
  const ExerciseView({
    super.key,
    required this.exercise,
    required this.enabled,
    required this.onChanged,
  });

  final Exercise exercise;
  final bool enabled;
  final AnswerChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final exercise = this.exercise;
    return switch (exercise) {
      ChoiceExercise() => ChoiceView(exercise: exercise, enabled: enabled, onChanged: onChanged),
      FillBlankExercise() => FillBlankView(exercise: exercise, enabled: enabled, onChanged: onChanged),
      MatchingExercise() => MatchingView(exercise: exercise, enabled: enabled, onChanged: onChanged),
      BuildSentenceExercise() =>
        BuildSentenceView(exercise: exercise, enabled: enabled, onChanged: onChanged),
      TranslateExercise() => TranslateView(exercise: exercise, enabled: enabled, onChanged: onChanged),
    };
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2)),
      ],
    );
  }
}

/// A large tappable answer option.
class OptionTile extends StatelessWidget {
  const OptionTile({super.key, required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.tint : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? AppColors.accent : AppColors.card, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}

class ChoiceView extends ConsumerStatefulWidget {
  const ChoiceView({super.key, required this.exercise, required this.enabled, required this.onChanged});

  final ChoiceExercise exercise;
  final bool enabled;
  final AnswerChanged onChanged;

  @override
  ConsumerState<ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends ConsumerState<ChoiceView> {
  int? _selected;
  late final List<int> _order;

  @override
  void initState() {
    super.initState();
    _order = mixedOrder(widget.exercise.options.of(explanationLanguage).length);
    if (widget.exercise.isListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
    }
  }

  void _speak() {
    final text = widget.exercise.audioText;
    if (text != null && mounted) ref.read(ttsProvider).speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final options = exercise.options.of(explanationLanguage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Prompt(
          label: exercise.isListening ? 'Аудіювання' : 'Оберіть правильний варіант',
          text: exercise.prompt.of(explanationLanguage),
        ),
        if (exercise.isListening) ...[
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _speak,
            icon: const Icon(Icons.volume_up),
            label: const Text('Прослухати ще раз'),
          ),
        ],
        const SizedBox(height: 20),
        for (final i in _order)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionTile(
              text: options[i],
              selected: _selected == i,
              onTap: widget.enabled
                  ? () {
                      setState(() => _selected = i);
                      widget.onChanged(i);
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}

class FillBlankView extends StatefulWidget {
  const FillBlankView({super.key, required this.exercise, required this.enabled, required this.onChanged});

  final FillBlankExercise exercise;
  final bool enabled;
  final AnswerChanged onChanged;

  @override
  State<FillBlankView> createState() => _FillBlankViewState();
}

class _FillBlankViewState extends State<FillBlankView> {
  int? _selected;
  late final List<int> _order = mixedOrder(widget.exercise.options.length);

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final selected = _selected;
    final shown = selected == null
        ? exercise.sentence
        : exercise.sentence.replaceFirst('___', exercise.options[selected]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          exercise.prompt.of(explanationLanguage),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Text(
            shown,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 20),
        for (final i in _order)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionTile(
              text: exercise.options[i],
              selected: selected == i,
              onTap: widget.enabled
                  ? () {
                      setState(() => _selected = i);
                      widget.onChanged(i);
                    }
                  : null,
            ),
          ),
      ],
    );
  }
}

class MatchingView extends StatefulWidget {
  const MatchingView({super.key, required this.exercise, required this.enabled, required this.onChanged});

  final MatchingExercise exercise;
  final bool enabled;
  final AnswerChanged onChanged;

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  late final List<String> _rights;
  final Set<String> _matchedLefts = {};
  final Set<String> _matchedRights = {};
  String? _selectedLeft;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _rights = [for (final pair in widget.exercise.pairs) pair.right.of(explanationLanguage)]
      ..shuffle(Random());
  }

  void _tapRight(String right) {
    final left = _selectedLeft;
    if (left == null) return;
    final pair = widget.exercise.pairs.firstWhere((p) => p.left == left);
    setState(() {
      if (pair.right.of(explanationLanguage) == right) {
        _matchedLefts.add(left);
        _matchedRights.add(right);
      } else {
        _mistakes++;
      }
      _selectedLeft = null;
    });
    if (_matchedLefts.length == widget.exercise.pairs.length) {
      widget.onChanged(_mistakes == 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Prompt(label: 'Пари слів', text: exercise.prompt.of(explanationLanguage)),
        const SizedBox(height: 8),
        const Text(
          'Натисніть слово ліворуч, потім його пару праворуч.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final pair in exercise.pairs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _matchedLefts.contains(pair.left)
                          ? _MatchedTile(text: pair.left)
                          : OptionTile(
                              text: pair.left,
                              selected: _selectedLeft == pair.left,
                              onTap: widget.enabled
                                  ? () => setState(() => _selectedLeft = pair.left)
                                  : null,
                            ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  for (final right in _rights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _matchedRights.contains(right)
                          ? _MatchedTile(text: right)
                          : OptionTile(
                              text: right,
                              selected: false,
                              onTap: widget.enabled ? () => _tapRight(right) : null,
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchedTile extends StatelessWidget {
  const _MatchedTile({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(color: AppColors.paleBlue, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy),
      ),
    );
  }
}

class BuildSentenceView extends StatefulWidget {
  const BuildSentenceView({super.key, required this.exercise, required this.enabled, required this.onChanged});

  final BuildSentenceExercise exercise;
  final bool enabled;
  final AnswerChanged onChanged;

  @override
  State<BuildSentenceView> createState() => _BuildSentenceViewState();
}

class _BuildSentenceViewState extends State<BuildSentenceView> {
  final List<int> _picked = [];
  late final List<int> _order = mixedOrder(widget.exercise.words.length);

  void _update(void Function() change) {
    setState(change);
    final words = widget.exercise.words;
    widget.onChanged(_picked.isEmpty ? null : [for (final i in _picked) words[i]]);
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final words = exercise.words;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Prompt(label: 'Складіть речення зі слів', text: exercise.prompt.of(explanationLanguage)),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 104),
            child: _picked.isEmpty
                ? const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Натискайте слова нижче по черзі',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final i in _picked)
                        _WordChip(
                          text: words[i],
                          filled: true,
                          onTap: widget.enabled ? () => _update(() => _picked.remove(i)) : null,
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in _order)
              if (!_picked.contains(i))
                _WordChip(
                  text: words[i],
                  filled: false,
                  onTap: widget.enabled ? () => _update(() => _picked.add(i)) : null,
                ),
          ],
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.text, required this.filled, required this.onTap});

  final String text;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.navy : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: filled ? AppColors.navy : AppColors.outline, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: filled ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TranslateView extends StatefulWidget {
  const TranslateView({super.key, required this.exercise, required this.enabled, required this.onChanged});

  final TranslateExercise exercise;
  final bool enabled;
  final AnswerChanged onChanged;

  @override
  State<TranslateView> createState() => _TranslateViewState();
}

class _TranslateViewState extends State<TranslateView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Prompt(label: 'Перекладіть англійською', text: widget.exercise.prompt.of(explanationLanguage)),
        const SizedBox(height: 20),
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: 'Ваш переклад',
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onChanged: (value) => widget.onChanged(value.trim().isEmpty ? null : value),
        ),
      ],
    );
  }
}
