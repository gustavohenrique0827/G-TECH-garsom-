import 'package:flutter/material.dart';

/// Shown only for the instant it takes [authControllerProvider] to resolve
/// the current session. The router redirect (see [appRouterProvider]) moves
/// away from here as soon as that finishes — there's no artificial delay.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.room_service_rounded, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('GTech Garçom', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
