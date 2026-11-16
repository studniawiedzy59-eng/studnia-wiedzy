import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/progress.dart';
import '../../state/providers.dart';
import '../lesson/lesson_screen.dart';

/// All units of the course with their lessons.
class PathTab extends ConsumerWidget {
  const PathTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final lessons = ref.watch(allLessonsProvider);
    final progress = ref.watch(progressProvider);
    if (course.hasError || lessons.hasError || progress.hasError) {
      return LoadErrorView(onRetry: () {
        ref.invalidate(courseProvider);
        ref.invalidate(allLessonsProvider);
        ref.invalidate(progressProvider);
      });
    }
    if (!course.hasValue || !lessons.hasValue || !progress.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final byId = {for (final lesson in lessons.value!) lesson.id: lesson};
    final completed = progress.value!.completedLessons;
    final units = course.value!.units;
    final order = course.value!.lessonIds;

    final items = <Widget>[
      const Text('Шлях', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
    ];
    // Only one level is open at a time: 280 units in one list would be too long.
    String? currentLevel;
    for (final unit in units) {
      if (unit.lessonIds.any((id) => !completed.contains(id))) {
        currentLevel = unit.cefr;
        break;
      }
    }
    final open = ref.watch(_openLevelProvider) ?? currentLevel ?? units.first.cefr;
    String? level;
    for (var i = 0; i < units.length; i++) {
      final unit = units[i];
      if (unit.cefr != level) {
        level = unit.cefr;
        final cefr = unit.cefr;
        final levelUnits = [for (final u in units) if (u.cefr == cefr) u];
        final ids = [for (final u in levelUnits) ...u.lessonIds];
        items.add(_LevelHeader(
          cefr: cefr,
          units: levelUnits.length,
          done: ids.where(completed.contains).length,
          total: ids.length,
          open: open == cefr,
          onTap: () => ref.read(_openLevelProvider.notifier).state = open == cefr ? '' : cefr,
        ));
      }
      if (unit.cefr != open) continue;
      items.add(_UnitCard(
        number: i + 1,
        unit: unit,
        lessons: [for (final id in unit.lessonIds) if (byId[id] != null) byId[id]!],
        completed: completed,
        order: order,
      ));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => items[index],
    );
  }
}

/// The level the learner opened by hand; `null` means "the level I am on".
final _openLevelProvider = StateProvider<String?>((ref) => null);

/// Names shown for each CEFR level in the learner's language.
const _levelNames = {
  'A0': 'Старт із нуля',
  'A1': 'Початковий',
  'A2': 'Елементарний',
  'B1': 'Середній',
  'B2': 'Вище середнього',
  'C1': 'Просунутий',
  'C2': 'Вільне володіння',
};

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.cefr,
    required this.units,
    required this.done,
    required this.total,
    required this.open,
    required this.onTap,
  });

  final String cefr;
  final int units;
  final int done;
  final int total;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = total == 0
        ? 'Розділів: $units · уроки ще пишуться'
        : 'Розділів: $units · пройдено уроків: $done з $total';
    return Material(
      color: AppColors.paleBlue,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Рівень $cefr · ${_levelNames[cefr] ?? ''}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(open ? Icons.expand_less : Icons.expand_more, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.number,
    required this.unit,
    required this.lessons,
    required this.completed,
    required this.order,
  });

  final int number;
  final CourseUnit unit;
  final List<Lesson> lessons;
  final Set<String> completed;
  final List<String> order;

  @override
  Widget build(BuildContext context) {
    final hasLessons = lessons.isNotEmpty;
    return AppCard(
      color: hasLessons ? AppColors.card : AppColors.locked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Розділ $number · ${unit.cefr}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            unit.title.of(explanationLanguage),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: hasLessons ? AppColors.ink : AppColors.muted,
            ),
          ),
          if (!hasLessons)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Уроки готуються',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
            ),
          for (final lesson in lessons)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _LessonTile(
                lesson: lesson,
                done: completed.contains(lesson.id),
                unlocked: isLessonUnlocked(order, completed, lesson.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.done, required this.unlocked});

  final Lesson lesson;
  final bool done;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final IconData icon;
    final Color iconColor;
    if (done) {
      background = AppColors.paleBlue;
      icon = Icons.check_circle;
      iconColor = AppColors.navy;
    } else if (unlocked) {
      background = AppColors.tint;
      icon = Icons.play_circle;
      iconColor = AppColors.accent;
    } else {
      background = AppColors.locked;
      icon = Icons.lock;
      iconColor = AppColors.muted;
    }
    return Semantics(
      label: unlocked ? null : 'Урок закрито. Спершу пройдіть попередній.',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: unlocked
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => LessonScreen(lessonId: lesson.id)),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lesson.title.of(explanationLanguage),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: unlocked ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
