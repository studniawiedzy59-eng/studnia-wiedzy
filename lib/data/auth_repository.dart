import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/backend_config.dart';

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

  /// Signs in with the Google account chosen on the phone.
  /// Returns false when the person closed the Google window.
  Future<bool> signInWithGoogle() async {
    final google = GoogleSignIn(serverClientId: googleWebClientId, scopes: const ['email']);
    final account = await google.signIn();
    if (account == null) return false;
    final tokens = await account.authentication;
    final idToken = tokens.idToken;
    if (idToken == null) throw const AuthException('Google did not return an ID token');
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: tokens.accessToken,
    );
    return true;
  }

  /// True when the signed-in person has not confirmed their age yet
  /// (accounts made with Google start without it).
  Future<bool> needsAge() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return false;
    final row = await _client.from('profiles').select('age_group').eq('id', id).maybeSingle();
    return row == null || row['age_group'] == null;
  }

  Future<void> setAge({required String ageGroup, required bool parentalConsent}) async {
    await _client.rpc<void>('set_my_age', params: {
      'p_age_group': ageGroup,
      'p_parental_consent': parentalConsent,
    });
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
  if (text.contains('google') || text.contains('id token')) {
    return 'Не вдалося увійти через Google. Спробуйте ще раз або увійдіть за поштою.';
  }
  return 'Не вдалося виконати дію. Перевірте інтернет і спробуйте ще раз.';
}
