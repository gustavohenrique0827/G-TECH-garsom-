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

  /// Public origin of the deployed client PWA — what printed QR codes and
  /// NFC tags encode (both always the exact same URL). Override per
  /// environment; the default is the production domain from the spec.
  static const String clientBaseUrl = String.fromEnvironment(
    'CLIENT_BASE_URL',
    defaultValue: 'https://garcom.gtech.com.br',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
