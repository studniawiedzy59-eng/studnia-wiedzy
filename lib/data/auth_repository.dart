import 'package:supabase_flutter/supabase_flutter.dart';

/// Sign-up, sign-in and account removal on the Movira server.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Returns true when the person must confirm the e-mail address before signing in.
  Future<bool> signUp({
    required String email,
    required String password,
    required String ageGroup,
    required bool parentalConsent,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'age_group': ageGroup, 'parental_consent': parentalConsent},
    );
    return response.session == null;
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) => _client.auth.resetPasswordForEmail(email);

  Future<void> signOut() => _client.auth.signOut();

  /// Deletes the account and every row of the person on the server.
  Future<void> deleteAccount() async {
    await _client.rpc<void>('delete_my_account');
    await _client.auth.signOut();
  }
}

/// A short Ukrainian explanation of a sign-in or sign-up error.
String authErrorText(Object error) {
  final text = error is AuthException ? error.message.toLowerCase() : '';
  if (text.contains('invalid login')) return 'Невірна пошта або пароль.';
  if (text.contains('not confirmed')) return 'Спершу підтвердьте пошту: ми надсилали лист із посиланням.';
  if (text.contains('already registered') || text.contains('already been registered')) {
    return 'Ця пошта вже зареєстрована. Спробуйте увійти.';
  }
  if (text.contains('password')) return 'Пароль занадто простий. Потрібно щонайменше 8 символів.';
  if (text.contains('database error') || text.contains('age_group') || text.contains('parental')) {
    return 'Не вдалося створити акаунт. Перевірте вік і згоду батьків.';
  }
  if (text.contains('rate limit') || text.contains('too many')) {
    return 'Забагато спроб. Зачекайте кілька хвилин і спробуйте ще раз.';
  }
  return 'Не вдалося виконати дію. Перевірте інтернет і спробуйте ще раз.';
}
