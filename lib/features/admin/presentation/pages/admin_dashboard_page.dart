import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controllers.dart';
import '../widgets/admin_scaffold.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;

    return AdminScaffold(
      title: 'Painel do Restaurante',
      currentIndex: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
      body: companyId == null
          ? const SizedBox.shrink()
          : _DashboardBody(companyId: companyId),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(adminDashboardStatsProvider(companyId)),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl3),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) =>
                const Text('Não foi possível carregar os indicadores.'),
            data: (stats) => Row(
              children: [
                Expanded(
                  child: StatCard(
                    value: '${stats.tablesCount}',
                    label: 'Mesas',
                    icon: Icons.table_bar_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    value: '${stats.waitersCount}',
                    label: 'Garçons',
                    icon: Icons.badge_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    value: '${stats.callsToday}',
                    label: 'Chamadas hoje',
                    icon: Icons.notifications_active_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Text('Gestão', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                _NavTile(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Mesas & QR Codes',
                  route: AppRoutes.adminTables,
                ),
                _NavTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Cardápio',
                  route: AppRoutes.adminMenu,
                ),
                _NavTile(
                  icon: Icons.badge_rounded,
                  label: 'Garçons',
                  route: AppRoutes.adminWaiters,
                ),
                _NavTile(
                  icon: Icons.settings_rounded,
                  label: 'Configurações',
                  route: AppRoutes.adminSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.go(route),
    );
  }
}
