import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

/// Shared chrome for the waiter's three screens. A plain bottom
/// [NavigationBar] driving three independently deep-linkable routes — no
/// nested [ShellRoute] needed for a surface this small and static.
class WaiterScaffold extends StatelessWidget {
  const WaiterScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.body,
    this.actions,
  });

  final String title;
  final int currentIndex;
  final Widget body;
  final List<Widget>? actions;

  static const _destinations = [
    (AppRoutes.waiterCalls, Icons.notifications_rounded, 'Chamadas'),
    (AppRoutes.waiterHistory, Icons.history_rounded, 'Histórico'),
    (AppRoutes.waiterProfile, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
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
