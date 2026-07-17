/// Compile-time configuration, injected via `--dart-define-from-file`.
///
/// Run with:
///   flutter run --dart-define-from-file=config/env.local.json
/// (see config/env.example.json for the expected keys)
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
