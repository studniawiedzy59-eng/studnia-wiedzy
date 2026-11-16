import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/my_words.dart';
import '../../state/providers.dart';
import 'word_editor.dart';

/// The learner's own dictionary: search, categories, edit, delete, mark as learned.
class MyWordsScreen extends ConsumerStatefulWidget {
  const MyWordsScreen({super.key});

  @override
  ConsumerState<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends ConsumerState<MyWordsScreen> {
  String _query = '';
  String? _category;
  bool _hideLearned = false;

  Future<void> _confirmDelete(MyWord word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити слово?'),
        content: Text('«${word.text}» зникне з вашого словника. Скасувати це не можна.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Залишити'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(myWordsProvider.notifier).remove(word.id);
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(myWordsProvider);
    final Widget body;
    if (saved.hasError) {
      body = LoadErrorView(onRetry: () => ref.invalidate(myWordsProvider));
    } else if (!saved.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final all = saved.value!;
      final categories = categoriesOf(all);
      final category = categories.contains(_category) ? _category : null;
      final shown = filterMyWords(all, query: _query, category: category, hideLearned: _hideLearned);
      final learnedCount = all.where((word) => word.learned).length;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          if (all.isEmpty)
            const AppCard(
              child: Text(
                'Тут будуть ваші власні слова. Натисніть «Додати слово» внизу, щоб зберегти перше.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            )
          else ...[
            Text(
              'Усього слів: ${all.length} · вивчено: $learnedCount',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Пошук слова або перекладу',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('Лише невивчені'),
                  selected: _hideLearned,
                  onSelected: (value) => setState(() => _hideLearned = value),
                ),
                for (final item in categories)
                  FilterChip(
                    label: Text(item),
                    selected: category == item,
                    onSelected: (value) => setState(() => _category = value ? item : null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              const AppCard(
                child: Text(
                  'Нічого не знайдено. Змініть пошук або зніміть фільтр.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            for (final word in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _WordCard(
                  word: word,
                  onListen: () => ref.read(ttsProvider).speak(word.text),
                  onToggleLearned: () =>
                      ref.read(myWordsProvider.notifier).replace(word.copyWith(learned: !word.learned)),
                  onEdit: () => showWordEditor(context, existing: word),
                  onDelete: () => _confirmDelete(word),
                ),
              ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Мій словник')),
      body: SafeArea(child: body),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWordEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Додати слово'),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.onListen,
    required this.onToggleLearned,
    required this.onEdit,
    required this.onDelete,
  });

  final MyWord word;
  final VoidCallback onListen;
  final VoidCallback onToggleLearned;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (word.ipa.isNotEmpty) word.ipa,
      if (word.category.trim().isNotEmpty) word.category.trim(),
    ].join(' · ');
    return AppCard(
      color: word.learned ? AppColors.paleBlue : AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                if (word.translation.isNotEmpty)
                  Text(
                    word.translation,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                if (details.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      details,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ),
                if (word.example.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(word.example, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                if (word.exampleTranslation.isNotEmpty)
                  Text(
                    word.exampleTranslation,
                    style: const TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Прослухати',
            onPressed: onListen,
            icon: const Icon(Icons.volume_up, color: AppColors.navy),
          ),
          IconButton(
            tooltip: word.learned ? 'Позначити як невивчене' : 'Позначити як вивчене',
            onPressed: onToggleLearned,
            icon: Icon(
              word.learned ? Icons.check_circle : Icons.check_circle_outline,
              color: word.learned ? AppColors.navy : AppColors.muted,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Інші дії',
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Редагувати')),
              PopupMenuItem(value: 'delete', child: Text('Видалити')),
            ],
          ),
        ],
      ),
    );
  }
}
