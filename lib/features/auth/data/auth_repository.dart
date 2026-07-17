import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Wraps Supabase Auth + `public.profiles` behind a single entry point.
///
/// There is exactly one login for every human user (master admin,
/// restaurant admin, waiter) — the role that decides which shell of the app
/// opens is resolved *after* authenticating, never chosen up front.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const Failure.auth('Não foi possível autenticar.');
      }

      return _loadProfile(user);
    } on AuthException catch (e) {
      throw Failure.auth(e.message);
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Resolves the current session into an [AppUser] by reading its profile
  /// row. Returns null when there is no active session.
  Future<AppUser?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadProfile(user);
  }

  Future<AppUser> _loadProfile(User user) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return AppUser.fromProfileRow(row, email: user.email ?? '');
    } on PostgrestException catch (e) {
      throw Failure.unknown('Perfil não encontrado: ${e.message}');
    }
  }
}
