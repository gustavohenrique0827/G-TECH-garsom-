import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase/supabase_providers.dart';
import '../../data/auth_repository.dart';
import '../../domain/entities/app_user.dart';

/// The currently authenticated [AppUser], or null when signed out.
///
/// Rebuilds automatically on every Supabase auth state change, which is
/// what lets the router redirect logic react to sign-in/sign-out without any
/// manual plumbing.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    ref.listen(authStateChangesProvider, (previous, next) {
      ref.invalidateSelf();
    });

    return ref.read(authRepositoryProvider).currentUser();
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}
