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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: units.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Text('Шлях', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900));
        }
        final unit = units[index - 1];
        return _UnitCard(
          number: index,
          unit: unit,
          lessons: [for (final id in unit.lessonIds) if (byId[id] != null) byId[id]!],
          completed: completed,
          order: order,
        );
      },
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
