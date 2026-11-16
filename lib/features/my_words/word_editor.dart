import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../domain/my_words.dart';
import '../../state/providers.dart';

/// Opens the small window for adding a word, or editing [existing].
Future<void> showWordEditor(BuildContext context, {MyWord? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.ground,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => WordEditor(existing: existing),
  );
}

class WordEditor extends ConsumerStatefulWidget {
  const WordEditor({super.key, this.existing});

  final MyWord? existing;

  @override
  ConsumerState<WordEditor> createState() => _WordEditorState();
}

class _WordEditorState extends ConsumerState<WordEditor> {
  late final TextEditingController _text;
  late final TextEditingController _translation;
  late final TextEditingController _ipa;
  late final TextEditingController _example;
  late final TextEditingController _exampleTranslation;
  late final TextEditingController _category;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final word = widget.existing;
    _text = TextEditingController(text: word?.text ?? '');
    _translation = TextEditingController(text: word?.translation ?? '');
    _ipa = TextEditingController(text: word?.ipa ?? '');
    _example = TextEditingController(text: word?.example ?? '');
    _exampleTranslation = TextEditingController(text: word?.exampleTranslation ?? '');
    _category = TextEditingController(text: word?.category ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    _translation.dispose();
    _ipa.dispose();
    _example.dispose();
    _exampleTranslation.dispose();
    _category.dispose();
    super.dispose();
  }

  void _listen() {
    final text = _text.text.trim();
    if (text.isNotEmpty) ref.read(ttsProvider).speak(text);
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Впишіть слово або вираз');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final existing = widget.existing;
    final all = await ref.read(myWordsProvider.future);
    final duplicate = findDuplicate(all, text, exceptId: existing?.id);
    if (duplicate != null) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Таке слово вже є'),
          content: Text(
            duplicate.translation.isEmpty
                ? '«${duplicate.text}» уже збережено у вашому словнику. Додати ще раз?'
                : '«${duplicate.text}» уже збережено з перекладом «${duplicate.translation}». Додати ще раз?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Не додавати'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Додати'),
            ),
          ],
        ),
      );
      if (proceed != true) {
        if (mounted) setState(() => _saving = false);
        return;
      }
    }
    final notifier = ref.read(myWordsProvider.notifier);
    if (existing == null) {
      await notifier.add(MyWord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        text: text,
        translation: _translation.text.trim(),
        ipa: _ipa.text.trim(),
        example: _example.text.trim(),
        exampleTranslation: _exampleTranslation.text.trim(),
        category: _category.text.trim(),
      ));
    } else {
      await notifier.replace(existing.copyWith(
        text: text,
        translation: _translation.text.trim(),
        ipa: _ipa.text.trim(),
        example: _example.text.trim(),
        exampleTranslation: _exampleTranslation.text.trim(),
        category: _category.text.trim(),
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    String? errorText,
    bool autofocus = false,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          suffixIcon: suffix,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = categoriesOf(ref.watch(myWordsProvider).value ?? const <MyWord>[]);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Нове слово' : 'Змінити слово',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Обов’язкове лише перше поле. Решту можна додати пізніше.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _field(
              _text,
              'Слово або вираз англійською',
              errorText: _error,
              autofocus: widget.existing == null,
              suffix: IconButton(
                tooltip: 'Прослухати вимову',
                onPressed: _listen,
                icon: const Icon(Icons.volume_up),
              ),
            ),
            _field(_translation, 'Переклад українською'),
            _field(_ipa, 'Транскрипція', hint: '/ˈkɒfi/'),
            _field(_example, 'Приклад речення англійською'),
            _field(_exampleTranslation, 'Переклад прикладу'),
            _field(_category, 'Категорія або тема', hint: 'Їжа, робота, подорожі…'),
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final category in categories)
                      ActionChip(
                        label: Text(category),
                        onPressed: () => setState(() => _category.text = category),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }
}
