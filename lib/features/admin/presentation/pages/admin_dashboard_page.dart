import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/stat_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controllers.dart';

/// Restaurant admin home. This foundation pass wires up the real,
/// realtime-backed KPIs (mesas, garçons, chamadas hoje); the management
/// screens listed in the product spec (cardápio, QR/NFC, configurações,
/// relatórios) are scaffolded as their own routes for the next phase.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Restaurante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
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

    return ListView(
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
        const _PlannedSection(
          items: [
            ('Mesas & QR/NFC', Icons.qr_code_2_rounded),
            ('Cardápio', Icons.menu_book_rounded),
            ('Garçons', Icons.badge_rounded),
            ('Configurações (logo, tema, Google)', Icons.settings_rounded),
            ('Relatórios', Icons.bar_chart_rounded),
          ],
        ),
      ],
    );
  }
}

class _PlannedSection extends StatelessWidget {
  const _PlannedSection({required this.items});

  final List<(String, IconData)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: items
            .map(
              (item) => ListTile(
                leading: Icon(item.$2, color: theme.colorScheme.onSurfaceVariant),
                title: Text(item.$1),
                trailing: const Icon(Icons.chevron_right_rounded),
                enabled: false,
              ),
            )
            .toList(),
      ),
    );
  }
}
