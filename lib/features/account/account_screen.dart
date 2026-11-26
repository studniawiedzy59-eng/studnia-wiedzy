import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/backend_config.dart';
import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../state/providers.dart';
import '../../state/sync_controller.dart';

/// Create an account, sign in, sign out or delete the account.
/// The app works without an account; an account only keeps progress on the
/// server, so it survives deleting the app or changing the phone.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  String _age = 'adult'; // adult = 16+, teen = 13-15, child = under 13
  bool _consent = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _message;
  bool _isError = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _say(String text, {bool error = true}) {
    setState(() {
      _message = text;
      _isError = error;
    });
  }

  Future<void> _submit() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || email.length < 5) {
      _say('Введіть правильну адресу пошти.');
      return;
    }
    if (password.length < 8) {
      _say('Пароль має містити щонайменше 8 символів.');
      return;
    }
    if (_signUp) {
      if (_age == 'child') {
        _say('Реєстрація доступна з 13 років.');
        return;
      }
      if (_age == 'teen' && !_consent) {
        _say('Для віку 13–15 років потрібна згода батьків: поставте позначку.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_signUp) {
        final needsConfirmation = await repository.signUp(
          email: email,
          password: password,
          ageGroup: _age == 'teen' ? '13-15' : '16+',
          parentalConsent: _age == 'teen' && _consent,
        );
        if (needsConfirmation) {
          setState(() => _signUp = false);
          _say('Ми надіслали лист на $email. Підтвердьте пошту за посиланням, потім увійдіть.', error: false);
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        await repository.signIn(email: email, password: password);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (error) {
      _say(authErrorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final signedIn = await repository.signInWithGoogle();
      if (!signedIn) return;
      if (await repository.needsAge()) {
        final ok = await _askAge(repository);
        if (!ok) {
          await repository.signOut();
          return;
        }
        await ref.read(syncControllerProvider.notifier).syncNow();
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _say(authErrorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// First sign-in with Google: asks the age. Under 13 the new account is removed.
  Future<bool> _askAge(AuthRepository repository) async {
    String age = 'adult';
    bool consent = false;
    final answer = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Ваш вік'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Це потрібно для безпеки дітей. Відповідь можна дати лише один раз.'),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Мені 16 років або більше'),
                  value: 'adult',
                  groupValue: age,
                  onChanged: (v) => setLocal(() => age = v!),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Мені 13–15 років'),
                  value: 'teen',
                  groupValue: age,
                  onChanged: (v) => setLocal(() => age = v!),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Мені менше 13 років'),
                  value: 'child',
                  groupValue: age,
                  onChanged: (v) => setLocal(() => age = v!),
                ),
                if (age == 'teen')
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Мої батьки або опікуни дозволили створити акаунт'),
                    value: consent,
                    onChanged: (v) => setLocal(() => consent = v ?? false),
                  ),
                if (age == 'child')
                  const Text('Акаунт доступний з 13 років. Нову реєстрацію буде скасовано.'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Скасувати')),
            TextButton(
              onPressed: (age == 'teen' && !consent) ? null : () => Navigator.of(dialogContext).pop(true),
              child: const Text('Продовжити'),
            ),
          ],
        ),
      ),
    );
    if (answer != true) return false;
    if (age == 'child') {
      try {
        await repository.deleteAccount();
      } catch (_) {}
      _say('Акаунт доступний з 13 років, тому ми його скасували.');
      return false;
    }
    try {
      await repository.setAge(ageGroup: age == 'teen' ? '13-15' : '16+', parentalConsent: age == 'teen' && consent);
      return true;
    } catch (error) {
      _say(authErrorText(error));
      return false;
    }
  }

  Future<void> _forgotPassword() async {
    final repository = ref.read(authRepositoryProvider);
    final email = _email.text.trim();
    if (repository == null) return;
    if (!email.contains('@')) {
      _say('Спершу введіть пошту, на яку надіслати лист для зміни пароля.');
      return;
    }
    try {
      await repository.sendPasswordReset(email);
      _say('Якщо така пошта зареєстрована, ми надіслали лист для зміни пароля.', error: false);
    } catch (error) {
      _say(authErrorText(error));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Видалити акаунт?'),
        content: const Text(
          'Акаунт і всі дані на сервері (прогрес, власні слова, відповіді опитування) будуть видалені назавжди. '
          'Дані на цьому телефоні залишаться. Скасувати це не можна.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Залишити')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Видалити')),
        ],
      ),
    );
    if (confirmed != true) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) return;
    setState(() => _busy = true);
    try {
      await repository.deleteAccount();
      await ref.read(syncControllerProvider.notifier).forgetUser();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _say('Не вдалося видалити акаунт. Перевірте інтернет і спробуйте ще раз.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(supabaseClientProvider) != null;
    final user = ref.watch(authUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Обліковий запис')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            if (!available)
              const AppCard(
                child: Text(
                  'Сервер у цій збірці недоступний. Застосунок працює без акаунта, прогрес зберігається на телефоні.',
                  style: TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              )
            else if (user != null)
              _signedIn(user.email ?? '')
            else
              _form(),
          ],
        ),
      ),
    );
  }

  Widget _signedIn(String email) {
    final sync = ref.watch(syncControllerProvider);
    final String status;
    if (sync.busy) {
      status = 'Синхронізація…';
    } else if (sync.failed) {
      status = 'Немає зв’язку із сервером. Дані на телефоні збережені, спробуємо знову при наступній зміні.';
    } else if (sync.lastSync != null) {
      final t = sync.lastSync!;
      status = 'Синхронізовано о ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    } else {
      status = 'Очікує синхронізації';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ви увійшли', style: TextStyle(fontSize: 14, color: AppColors.muted)),
              Text(email, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(status, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              const SizedBox(height: 4),
              const Text(
                'Прогрес, власні слова й відповіді опитування зберігаються в акаунті: їх можна відновити після видалення застосунку чи на новому телефоні.',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: _busy ? null : () => ref.read(syncControllerProvider.notifier).syncNow(),
          child: const Text('Синхронізувати зараз'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy
              ? null
              : () async {
                  await ref.read(authRepositoryProvider)?.signOut();
                  if (mounted) Navigator.of(context).pop();
                },
          child: const Text('Вийти'),
        ),
        TextButton(
          onPressed: _busy ? null : _confirmDelete,
          child: const Text('Видалити акаунт'),
        ),
        if (_message != null) _messageBox(),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Вхід')),
            ButtonSegment(value: true, label: Text('Реєстрація')),
          ],
          selected: {_signUp},
          onSelectionChanged: (value) => setState(() {
            _signUp = value.first;
            _message = null;
          }),
        ),
        if (googleWebClientId.isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              side: const BorderSide(color: AppColors.outline),
            ),
            onPressed: _busy ? null : _google,
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Продовжити з Google', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('або за поштою', style: TextStyle(color: AppColors.muted))),
        ],
        const SizedBox(height: 16),
        const Text(
          'Акаунт не обов’язковий. З ним прогрес не зникне, якщо видалити застосунок або змінити телефон.',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Пошта', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _hidePassword,
          autofillHints: [_signUp ? AutofillHints.newPassword : AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Пароль (мінімум 8 символів)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: _hidePassword ? 'Показати пароль' : 'Сховати пароль',
              icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
        ),
        if (_signUp) ...[
          const SizedBox(height: 16),
          const Text('Ваш вік', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Мені 16 років або більше'),
            value: 'adult',
            groupValue: _age,
            onChanged: (v) => setState(() => _age = v!),
          ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Мені 13–15 років'),
            value: 'teen',
            groupValue: _age,
            onChanged: (v) => setState(() => _age = v!),
          ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Мені менше 13 років'),
            value: 'child',
            groupValue: _age,
            onChanged: (v) => setState(() => _age = v!),
          ),
          if (_age == 'teen')
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Мої батьки або опікуни дозволили створити акаунт'),
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
            ),
          if (_age == 'child')
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Акаунт доступний з 13 років. Застосунок усе одно можна використовувати без акаунта.',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: (_busy || (_signUp && _age == 'child')) ? null : _submit,
          child: _busy
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : Text(_signUp ? 'Створити акаунт' : 'Увійти'),
        ),
        if (!_signUp)
          TextButton(onPressed: _busy ? null : _forgotPassword, child: const Text('Забули пароль?')),
        if (_message != null) _messageBox(),
      ],
    );
  }

  Widget _messageBox() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        color: _isError ? AppColors.tint : AppColors.paleBlue,
        child: Text(
          _message!,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _isError ? AppColors.accentDark : AppColors.navy,
          ),
        ),
      ),
    );
  }
}
