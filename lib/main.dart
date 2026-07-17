import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  // Clean path URLs on web (no /#/) — required so the QR/NFC URL printed
  // on tables is exactly https://…/r/{companyId}/m/{tableId}. The hosting
  // server must rewrite unknown paths to index.html (standard SPA setup).
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  assert(
    Env.isConfigured,
    'SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY not set. Run with '
    '--dart-define-from-file=config/env.local.json '
    '(copy config/env.example.json first).',
  );

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  runApp(const ProviderScope(child: AppRoot()));
}
