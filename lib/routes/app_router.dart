import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_login_page.dart';
import '../features/demo/presentation/pages/client_demo_page.dart';
import '../features/demo/presentation/pages/waiter_demo_page.dart';
import '../features/gtech/presentation/pages/gtech_home_page.dart';
import '../features/home/presentation/pages/home_shell_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,

    debugLogDiagnostics: true,

    routes: [

      GoRoute(
        path: AppRoutes.splash,
        name: "splash",
        builder: (_, __) => const SplashPage(),
      ),

      GoRoute(
        path: AppRoutes.home,
        name: "home",
        builder: (_, __) => const HomeShellPage(),
      ),

      GoRoute(
        path: AppRoutes.cliente,
        name: "cliente",
        builder: (_, __) => const ClientDemoPage(),
      ),

      GoRoute(
        path: AppRoutes.waiterLogin,
        name: "waiter-login",
        builder: (_, __) => const WaiterDemoPage(),
      ),

      GoRoute(
        path: AppRoutes.adminLogin,
        name: "admin-login",
        builder: (_, __) => const AdminLoginPage(),
      ),

      GoRoute(
        path: AppRoutes.gtech,
        name: "gtech",
        builder: (_, __) => const GtechHomePage(),
      ),
    ],

    redirect: (context, state) async {

      // TODO:
      // final session = Supabase.instance.client.auth.currentSession;

      // if(session == null && state.uri.path.startsWith('/admin')){
      //    return AppRoutes.adminLogin;
      // }

      return null;
    },

    errorBuilder: (_, state) => const NotFoundPage(),
  );
});