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

  // A bare `assert` here used to fail silently into a blank page (asserts
  // throw before runApp in debug, and are stripped entirely in release —
  // either way nothing ever mounts). Render an explicit, readable error
  // screen instead, so a missing --dart-define-from-file is obvious rather
  // than a mystery blank screen.
  if (!Env.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  runApp(const ProviderScope(child: AppRoot()));
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF14161C),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_suggest_rounded, color: Colors.white70, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'Configuração do Supabase ausente',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rode o app com:\n'
                  'flutter run --dart-define-from-file=config/env.local.json\n\n'
                  '(copie config/env.example.json para config/env.local.json e '
                  'preencha SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY primeiro)',
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No VS Code, use a configuração de Run "GTech Garçom" em .vscode/launch.json — '
                  'ela já inclui essa flag.',
                  style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
