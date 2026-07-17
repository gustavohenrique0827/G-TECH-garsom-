import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

/// Shared chrome for the restaurant admin area — bottom navigation over
/// five independently deep-linkable routes, mirroring [WaiterScaffold].
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final int currentIndex;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  static const _destinations = [
    (AppRoutes.adminDashboard, Icons.dashboard_rounded, 'Início'),
    (AppRoutes.adminTables, Icons.table_bar_rounded, 'Mesas'),
    (AppRoutes.adminMenu, Icons.menu_book_rounded, 'Cardápio'),
    (AppRoutes.adminWaiters, Icons.badge_rounded, 'Garçons'),
    (AppRoutes.adminSettings, Icons.settings_rounded, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_destinations[i].$1),
        destinations: _destinations
            .map((d) => NavigationDestination(icon: Icon(d.$2), label: d.$3))
            .toList(),
      ),
    );
  }
}
