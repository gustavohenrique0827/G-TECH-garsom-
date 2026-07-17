import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/empty_state.dart';
import '../../../../design_system/widgets/stat_card.dart';
import '../../../../design_system/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/controllers/companies_controllers.dart';
import '../../../dashboard/presentation/controllers/dashboard_controllers.dart';

/// GTech master admin home — platform-wide KPIs and the list of tenant
/// companies. Suspension/cancellation actions, plans and billing are the
/// next phase; this pass proves the multi-tenant read path end-to-end.
class GtechDashboardPage extends ConsumerWidget {
  const GtechDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(gtechDashboardStatsProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GTech · Painel Global'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl3),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Text('Não foi possível carregar os indicadores.'),
            data: (stats) => Row(
              children: [
                Expanded(
                  child: StatCard(
                    value: '${stats.companiesCount}',
                    label: 'Empresas',
                    icon: Icons.storefront_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: StatCard(
                    value: '${stats.activeCompaniesCount}',
                    label: 'Ativas',
                    icon: Icons.check_circle_rounded,
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
          Text('Empresas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          companiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Não foi possível carregar as empresas.',
            ),
            data: (companies) {
              if (companies.isEmpty) {
                return const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Nenhuma empresa cadastrada ainda.',
                );
              }
              return Card(
                child: Column(
                  children: companies.map((c) => _CompanyTile(company: c)).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (company.status) {
      CompanyStatus.active => theme.colorScheme.primary,
      CompanyStatus.suspended => Colors.orange,
      CompanyStatus.cancelled => theme.colorScheme.error,
    };

    return ListTile(
      leading: const Icon(Icons.storefront_rounded),
      title: Text(company.name),
      trailing: StatusBadge(label: company.status.label, color: color),
    );
  }
}
