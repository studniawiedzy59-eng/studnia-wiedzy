import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/learner_profile.dart';
import '../../domain/practice_topics.dart';
import '../../state/providers.dart';
import '../home/root_screen.dart';

/// Shows the first-launch quiz until it is finished or skipped, then the app.
/// If the saved answers cannot be read the app opens anyway.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(learnerProfileProvider);
    if (profile.hasError) return const RootScreen();
    if (!profile.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (profile.value == null) return const OnboardingScreen();
    return const RootScreen();
  }
}

const Map<String, IconData> _goalIcons = {
  'travel': Icons.flight_takeoff,
  'work': Icons.work_outline,
  'study': Icons.school_outlined,
  'people': Icons.groups_outlined,
  'move': Icons.public,
  'fun': Icons.emoji_emotions_outlined,
};

const int _lastStep = 6;

/// Six short questions and a personal plan. With [editing] the learner changes
/// earlier answers and the screen closes at the end.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.editing = false});

  final bool editing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  late final TextEditingController _name;
  late Set<String> _goals;
  late String _level;
  late Set<String> _interests;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(learnerProfileProvider).value;
    final start = (existing != null && existing.hasPlan) ? existing : const LearnerProfile();
    _name = TextEditingController(text: start.name);
    _goals = {...start.goals};
    _level = start.level;
    _interests = {...start.interests};
    _minutes = start.dailyMinutes;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  LearnerProfile get _profile => LearnerProfile(
        name: _name.text.trim(),
        goals: _goals,
        level: _level,
        interests: _interests,
        dailyMinutes: _minutes,
      );

  Future<void> _finish(LearnerProfile profile) async {
    await ref.read(learnerProfileProvider.notifier).save(profile);
    if (widget.editing && mounted) Navigator.of(context).pop();
  }

  void _toggle(Set<String> set, String id) {
    setState(() => set.contains(id) ? set.remove(id) : set.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _lastStep;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: _step > 0
                        ? IconButton(
                            tooltip: 'Назад',
                            onPressed: () => setState(() => _step--),
                            icon: const Icon(Icons.arrow_back),
                          )
                        : null,
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / (_lastStep + 1),
                        minHeight: 8,
                        backgroundColor: AppColors.tint,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.editing)
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Закрити'),
                    )
                  else if (!last)
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: () => _finish(const LearnerProfile(skipped: true)),
                      child: const Text('Пропустити'),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(key: ValueKey(_step), child: _body()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: FilledButton(
                onPressed: last ? () => _finish(_profile) : () => setState(() => _step++),
                child: Text(last ? 'Почати навчання' : 'Далі'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _welcome();
      case 1:
        return _question('Як вас звати?', 'Можна пропустити: це лише для привітання.', [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            maxLength: 24,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Ваше ім’я',
              border: OutlineInputBorder(),
            ),
          ),
        ]);
      case 2:
        return _question('Навіщо вам англійська?', 'Оберіть усе, що підходить.', [
          for (final e in goalLabels.entries)
            _Choice(
              label: e.value,
              icon: _goalIcons[e.key],
              selected: _goals.contains(e.key),
              onTap: () => _toggle(_goals, e.key),
            ),
        ]);
      case 3:
        return _question('Який у вас рівень зараз?', 'Відповідайте чесно: так план вийде кращим.', [
          for (final e in levelLabels.entries)
            _Choice(
              label: e.value,
              selected: _level == e.key,
              onTap: () => setState(() => _level = e.key),
            ),
        ]);
      case 4:
        return _question('Що вам найцікавіше?', 'Ці теми будуть першими у «Практиці».', [
          for (final t in practiceTopics)
            _Choice(
              label: t.title,
              selected: _interests.contains(t.id),
              onTap: () => _toggle(_interests, t.id),
            ),
        ]);
      case 5:
        return _question('Скільки часу на день?', 'Краще менше, але щодня.', [
          for (final m in dailyMinuteOptions)
            _Choice(
              label: '$m хвилин на день',
              selected: _minutes == m,
              onTap: () => setState(() => _minutes = m),
            ),
        ]);
      default:
        return _plan();
    }
  }

  Widget _welcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Image.asset(
            'assets/images/photo_people.jpg',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/topic_people.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(height: 200),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Вітаємо в Movira', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text(
          'П’ять коротких питань, і ми складемо план саме для вас. Це займе хвилину.',
          style: TextStyle(fontSize: 17, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _question(String title, String hint, List<Widget> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(hint, style: const TextStyle(fontSize: 15, color: AppColors.muted)),
        const SizedBox(height: 20),
        for (final option in options) ...[option, const SizedBox(height: 10)],
      ],
    );
  }

  Widget _plan() {
    final profile = _profile;
    final topics = orderTopics(practiceTopics, profile.interests).where((t) => profile.interests.contains(t.id)).toList();
    final name = profile.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Ваш план' : '$name, ваш план',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        _PlanRow(icon: Icons.timer_outlined, title: '${profile.dailyMinutes} хвилин на день', text: dailyAdvice(profile.dailyMinutes)),
        _PlanRow(icon: Icons.signal_cellular_alt, title: levelLabels[profile.level]!, text: levelAdvice(profile.level)),
        if (profile.goals.isNotEmpty)
          _PlanRow(
            icon: Icons.flag_outlined,
            title: 'Ваші цілі',
            text: [for (final id in goalLabels.keys) if (profile.goals.contains(id)) goalLabels[id]!].join(', '),
          ),
        if (topics.isNotEmpty)
          _PlanRow(
            icon: Icons.forum_outlined,
            title: 'Практика насамперед',
            text: topics.map((t) => t.title).join(', '),
          ),
        const SizedBox(height: 4),
        const Text(
          'Відповіді можна змінити в «Профілі». Репетитор Анна з’явиться після підключення AI.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? AppColors.tint : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? AppColors.accent : AppColors.outline, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.accentDark),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (selected) const Icon(Icons.check_circle, color: AppColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(text, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
