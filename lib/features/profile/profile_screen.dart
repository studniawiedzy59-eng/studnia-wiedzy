import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/sm2.dart';
import '../../state/providers.dart';

/// Progress numbers and the few settings that exist so far.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Скинути прогрес?'),
        content: const Text('Пройдені уроки, слова й серія днів будуть видалені з цього пристрою. Скасувати це не можна.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Залишити'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Скинути'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(progressProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    if (progress.hasError) {
      return LoadErrorView(onRetry: () => ref.invalidate(progressProvider));
    }
    if (!progress.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }
    final state = progress.value!;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Профіль', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _Stat(value: '${state.currentStreak(now)}', label: 'днів поспіль')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(value: '${state.completedLessons.length}', label: 'уроків пройдено')),
            const SizedBox(width: 10),
            Expanded(child: _Stat(value: '${state.words.length}', label: 'слів у словнику')),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Цього тижня', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _WeekRow(secondsByDay: state.secondsByDay, now: now),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Мій репетитор', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        const Text('Анна', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accent)),
                        const SizedBox(height: 4),
                        const Text(
                          'Розмови з Анною з’являться після підключення AI.',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/tutor_anna.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 130, height: 130),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Text(
            'Сьогодні: ${state.minutesOn(now)} хв навчання',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        const AppCard(
          child: Text(
            'Прогрес зберігається на цьому пристрої. Обліковий запис і синхронізація з’являться в наступній версії.',
            style: TextStyle(fontSize: 15, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _confirmReset(context, ref),
          child: const Text('Скинути прогрес'),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Версія збірки: ${String.fromEnvironment('BUILD', defaultValue: 'локальна')}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.accent),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// The last seven days, today on the right; a filled circle marks a day with learning.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.secondsByDay, required this.now});

  final Map<String, int> secondsByDay;
  final DateTime now;

  static const _names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(now);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var back = 6; back >= 0; back--)
          _Day(
            label: _names[today.subtract(Duration(days: back)).weekday - 1],
            active: (secondsByDay[dayKey(today.subtract(Duration(days: back)))] ?? 0) > 0,
            isToday: back == 0,
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.label, required this.active, required this.isToday});

  final String label;
  final bool active;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${active ? 'навчання було' : 'навчання не було'}',
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.accent : AppColors.tint,
              border: isToday ? Border.all(color: AppColors.accentDark, width: 2) : null,
            ),
            child: active ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
              color: isToday ? AppColors.accentDark : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
