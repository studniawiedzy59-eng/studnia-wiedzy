import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
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
  });

  final int number;
  final CourseUnit unit;
  final List<Lesson> lessons;
  final Set<String> completed;

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
              child: Material(
                color: completed.contains(lesson.id) ? AppColors.paleBlue : AppColors.tint,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => LessonScreen(lessonId: lesson.id)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          completed.contains(lesson.id) ? Icons.check_circle : Icons.play_circle,
                          color: completed.contains(lesson.id) ? AppColors.navy : AppColors.accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lesson.title.of(explanationLanguage),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
