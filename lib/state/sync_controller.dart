import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/learner_profile.dart';
import '../domain/my_words.dart';
import '../domain/progress.dart';
import '../domain/sync_merge.dart';
import 'providers.dart';

class SyncState {
  const SyncState({this.busy = false, this.lastSync, this.failed = false});

  final bool busy;
  final DateTime? lastSync;
  final bool failed;
}

/// Keeps the account on the server and this phone in step.
///
/// The phone stays the main copy: everything works offline and is saved here
/// first. While signed in, changes are sent to the server a few seconds later.
/// Signing in merges this phone's data with the account's, unless another
/// person used this phone before: then the phone is replaced by the account.
class SyncController extends Notifier<SyncState> {
  static const _lastUserKey = 'sync_user_id';
  static const _debounce = Duration(seconds: 4);

  Timer? _timer;
  bool _working = false;
  final Map<String, String> _lastPushed = {};

  @override
  SyncState build() {
    ref.listen<AsyncValue<User?>>(authUserProvider, (_, next) {
      final user = next.value;
      if (user != null) unawaited(_fullSync(user.id));
    }, fireImmediately: true);
    ref.listen(progressProvider, (_, __) => _schedule());
    ref.listen(myWordsProvider, (_, __) => _schedule());
    ref.listen(learnerProfileProvider, (_, __) => _schedule());
    ref.onDispose(() => _timer?.cancel());
    return const SyncState();
  }

  String? get _userId => ref.read(authUserProvider).value?.id;

  void _schedule() {
    if (_userId == null || _working) return;
    _timer?.cancel();
    _timer = Timer(_debounce, () => unawaited(_pushChanges()));
  }

  /// Sends the data to the server right away (used by the "Synchronize" button).
  Future<void> syncNow() async {
    final id = _userId;
    if (id != null) await _fullSync(id);
  }

  Future<void> forgetUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserKey);
    _lastPushed.clear();
  }

  Future<void> _fullSync(String userId) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null || _working) return;
    _working = true;
    state = SyncState(busy: true, lastSync: state.lastSync);
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUser = prefs.getString(_lastUserKey);
      // Another person used this phone: never mix their data into this account.
      final foreign = lastUser != null && lastUser != userId;

      final remoteProgress = await _fetch(client, 'progress', userId);
      final remoteWords = await _fetch(client, 'my_words', userId);
      final remoteQuiz = await _fetch(client, 'learner_profiles', userId);

      final localProgress = await ref.read(progressProvider.future);
      final localWords = await ref.read(myWordsProvider.future);
      final localQuiz = await ref.read(learnerProfileProvider.future);

      final Progress progress;
      if (foreign) {
        progress = remoteProgress == null ? const Progress.empty() : Progress.fromJson(remoteProgress);
      } else if (remoteProgress == null) {
        progress = localProgress;
      } else {
        progress = mergeProgress(localProgress, Progress.fromJson(remoteProgress));
      }

      final remoteWordList = _wordsFrom(remoteWords);
      final List<MyWord> words;
      if (foreign) {
        words = remoteWordList;
      } else {
        words = mergeMyWords(localWords, remoteWordList);
      }

      final remoteQuizProfile = remoteQuiz == null ? null : LearnerProfile.fromJson(remoteQuiz);
      final LearnerProfile? quiz;
      if (foreign) {
        quiz = remoteQuizProfile;
      } else if (localQuiz != null && localQuiz.hasPlan) {
        quiz = localQuiz;
      } else {
        quiz = remoteQuizProfile ?? localQuiz;
      }

      await ref.read(progressProvider.notifier).replaceWith(progress);
      await ref.read(myWordsProvider.notifier).replaceAll(words);
      await ref.read(learnerProfileProvider.notifier).replace(quiz);

      _lastPushed.clear();
      await _push(client, userId, progress: progress, words: words, quiz: quiz);
      await prefs.setString(_lastUserKey, userId);
      state = SyncState(lastSync: DateTime.now());
    } catch (_) {
      // Offline or a server hiccup: the phone keeps everything, next change retries.
      state = SyncState(lastSync: state.lastSync, failed: true);
    } finally {
      _working = false;
    }
  }

  Future<void> _pushChanges() async {
    final client = ref.read(supabaseClientProvider);
    final userId = _userId;
    if (client == null || userId == null || _working) return;
    _working = true;
    try {
      await _push(
        client,
        userId,
        progress: await ref.read(progressProvider.future),
        words: await ref.read(myWordsProvider.future),
        quiz: await ref.read(learnerProfileProvider.future),
      );
      state = SyncState(lastSync: DateTime.now());
    } catch (_) {
      state = SyncState(lastSync: state.lastSync, failed: true);
    } finally {
      _working = false;
    }
  }

  Future<void> _push(
    SupabaseClient client,
    String userId, {
    required Progress progress,
    required List<MyWord> words,
    required LearnerProfile? quiz,
  }) async {
    await _upsertIfChanged(client, 'progress', userId, progress.toJson());
    await _upsertIfChanged(client, 'my_words', userId, {'items': [for (final w in words) w.toJson()]});
    if (quiz != null) await _upsertIfChanged(client, 'learner_profiles', userId, quiz.toJson());
  }

  Future<void> _upsertIfChanged(
    SupabaseClient client,
    String table,
    String userId,
    Map<String, dynamic> data,
  ) async {
    final encoded = jsonEncode(data);
    if (_lastPushed[table] == encoded) return;
    await client.from(table).upsert({'user_id': userId, 'data': data});
    _lastPushed[table] = encoded;
  }

  Future<Map<String, dynamic>?> _fetch(SupabaseClient client, String table, String userId) async {
    final row = await client.from(table).select('data').eq('user_id', userId).maybeSingle();
    final data = row?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  List<MyWord> _wordsFrom(Map<String, dynamic>? data) {
    final items = data?['items'];
    if (items is! List) return const [];
    final result = <MyWord>[];
    for (final item in items) {
      try {
        result.add(MyWord.fromJson(Map<String, dynamic>.from(item as Map)));
      } catch (_) {
        // A damaged word is skipped; the rest still arrive.
      }
    }
    return result;
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
