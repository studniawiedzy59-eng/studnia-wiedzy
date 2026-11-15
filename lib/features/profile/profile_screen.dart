import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
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
