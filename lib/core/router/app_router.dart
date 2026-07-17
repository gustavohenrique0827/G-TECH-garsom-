import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_menu_page.dart';
import '../../features/admin/presentation/pages/admin_settings_page.dart';
import '../../features/admin/presentation/pages/admin_tables_page.dart';
import '../../features/admin/presentation/pages/admin_waiters_page.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/client/presentation/pages/client_table_page.dart';
import '../../features/gtech/presentation/pages/gtech_dashboard_page.dart';
import '../../features/menu/presentation/pages/menu_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/waiter/presentation/pages/waiter_calls_page.dart';
import '../../features/waiter/presentation/pages/waiter_history_page.dart';
import '../../features/waiter/presentation/pages/waiter_profile_page.dart';
import 'app_routes.dart';

/// Bridges Riverpod's [authControllerProvider] into a [Listenable] for
/// go_router's `refreshListenable`. This is deliberately *not* implemented
/// by having `appRouterProvider` itself `ref.watch` the auth state — doing
/// that recreates the whole [GoRouter] on every auth change, which drops
/// its knowledge of the current browser location (it falls back to
/// [AppRoutes.splash]) and was breaking the public `/r/:companyId/m/:tableId`
/// route on reload. `refreshListenable` instead re-runs `redirect` on the
/// *same* router instance, location intact.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, _) => const LoginPage(),
      ),

      // Public — no auth. Reached via QR Code or NFC, both the same URL.
      GoRoute(
        path: AppRoutes.clientTable,
        name: 'client-table',
        builder: (_, state) => ClientTablePage(
          companyId: state.pathParameters['companyId']!,
          tableId: state.pathParameters['tableId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.clientMenu,
        name: 'client-menu',
        builder: (_, state) =>
            MenuPage(companyId: state.pathParameters['companyId']!),
      ),

      // Waiter.
      GoRoute(
        path: AppRoutes.waiterCalls,
        name: 'waiter-calls',
        builder: (_, _) => const WaiterCallsPage(),
      ),
      GoRoute(
        path: AppRoutes.waiterHistory,
        name: 'waiter-history',
        builder: (_, _) => const WaiterHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.waiterProfile,
        name: 'waiter-profile',
        builder: (_, _) => const WaiterProfilePage(),
      ),

      // Restaurant admin.
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (_, _) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.adminTables,
        name: 'admin-tables',
        builder: (_, _) => const AdminTablesPage(),
      ),
      GoRoute(
        path: AppRoutes.adminMenu,
        name: 'admin-menu',
        builder: (_, _) => const AdminMenuPage(),
      ),
      GoRoute(
        path: AppRoutes.adminWaiters,
        name: 'admin-waiters',
        builder: (_, _) => const AdminWaitersPage(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        name: 'admin-settings',
        builder: (_, _) => const AdminSettingsPage(),
      ),

      // GTech master admin.
      GoRoute(
        path: AppRoutes.gtechDashboard,
        name: 'gtech-dashboard',
        builder: (_, _) => const GtechDashboardPage(),
      ),
    ],

    redirect: (context, state) {
      final loc = state.matchedLocation;

      // The client PWA is public — QR/NFC never carry a session.
      if (loc.startsWith('/r/')) return null;

      // Read (not watch) — `refreshListenable` above is what re-triggers
      // this callback; reading here just needs the state to be fresh.
      final authState = ref.read(authControllerProvider);

      if (authState.isLoading) {
        // Park on splash while the session resolves, carrying the intended
        // destination so a deep link (e.g. /admin/mesas pasted in the
        // address bar) isn't lost to the post-login home redirect.
        if (loc == AppRoutes.splash) return null;
        return Uri(
          path: AppRoutes.splash,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }

      final user = authState.valueOrNull;

      if (user == null) {
        return loc == AppRoutes.login ? null : AppRoutes.login;
      }

      // Authenticated: bounce away from splash/login into the right shell,
      // restoring the parked deep link when there is one.
      if (loc == AppRoutes.splash || loc == AppRoutes.login) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty && from != AppRoutes.splash) {
          return from;
        }
        return user.role.homePath;
      }

      // Role guard — e.g. a waiter typing /admin in the address bar.
      final allowedPrefix = switch (user.role) {
        UserRole.masterAdmin => '/gtech',
        UserRole.admin => '/admin',
        UserRole.waiter => '/garcom',
      };
      if (!loc.startsWith(allowedPrefix)) return user.role.homePath;

      return null;
    },

    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Página não encontrada: ${state.uri}')),
    ),
  );
});
