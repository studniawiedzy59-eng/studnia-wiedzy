import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../state/providers.dart';
import '../lesson/lesson_screen.dart';
import '../my_words/word_editor.dart';
import '../path/path_screen.dart';
import '../profile/profile_screen.dart';
import '../words/words_screen.dart';

/// The four main sections with the bottom navigation bar.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            HomeTab(onOpenWords: () => setState(() => _index = 2)),
            const PathTab(),
            const WordsTab(),
            const ProfileTab(),
          ],
        ),
      ),
      floatingActionButton: (_index == 0 || _index == 2)
          ? FloatingActionButton.extended(
              tooltip: 'Додати слово до мого словника',
              onPressed: () => showWordEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('Слово'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Головна'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Шлях'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Словник'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профіль'),
        ],
      ),
    );
  }
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onOpenWords});

  final VoidCallback onOpenWords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(allLessonsProvider);
    final progress = ref.watch(progressProvider);
    if (lessons.hasError || progress.hasError) {
      return LoadErrorView(onRetry: () {
        ref.invalidate(allLessonsProvider);
        ref.invalidate(progressProvider);
      });
    }
    if (!lessons.hasValue || !progress.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final allLessons = lessons.value!;
    final state = progress.value!;
    final now = DateTime.now();
    Lesson? next;
    for (final lesson in allLessons) {
      if (!state.completedLessons.contains(lesson.id)) {
        next = lesson;
        break;
      }
    }
    final dueCount = state.dueWordKeys(now).length;
    final streak = state.currentStreak(now);
    final nextLesson = next;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Movira', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, size: 18, color: AppColors.accentDark),
                  const SizedBox(width: 6),
                  Text(
                    'Днів поспіль: $streak',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentDark),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Row(
            children: [
              const Expanded(
                child: Text('Сьогодні', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Text(
                '${state.minutesOn(now)} хв навчання',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (nextLesson != null)
          AppCard(
            color: AppColors.accent,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Наступний урок · ${nextLesson.cefr}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  nextLesson.title.of(explanationLanguage),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  nextLesson.goal.of(explanationLanguage),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.accentDark,
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => LessonScreen(lessonId: nextLesson.id)),
                  ),
                  child: const Text('Почати урок'),
                ),
              ],
            ),
          )
        else
          const AppCard(
            color: AppColors.paleBlue,
            child: Text(
              'Усі доступні уроки пройдено. Нові уроки з’являться з оновленням.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dueCount',
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.accent),
              ),
              const Text(
                'слів чекають на повторення',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: onOpenWords,
                child: const Text('Відкрити словник'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
