import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/empty_state.dart';
import '../../../../design_system/widgets/stat_card.dart';
import '../../../../design_system/widgets/status_badge.dart';
import '../../../../shared/utils/dialogs.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../companies/data/companies_repository.dart';
import '../../../companies/domain/entities/company.dart';
import '../../../companies/presentation/controllers/companies_controllers.dart';
import '../../../dashboard/presentation/controllers/dashboard_controllers.dart';
import '../../../staff/presentation/widgets/invite_user_dialog.dart';

/// GTech master admin home — platform KPIs plus full tenant management:
/// create companies, suspend/reactivate/cancel them, and create each
/// company's admin account.
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCompany(context, ref),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Nova empresa'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          96,
        ),
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
                  subtitle: 'Crie a primeira pelo botão "Nova empresa".',
                );
              }
              return Card(
                child: Column(
                  children: companies
                      .map((c) => _CompanyTile(company: c))
                      .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createCompany(BuildContext context, WidgetRef ref) async {
    final name = await promptText(
      context,
      title: 'Nova empresa',
      label: 'Nome do restaurante',
      confirmLabel: 'Criar',
    );
    if (name == null) return;

    try {
      await ref.read(companiesRepositoryProvider).createCompany(name: name);
      ref.invalidate(allCompaniesProvider);
      ref.invalidate(gtechDashboardStatsProvider);
    } catch (_) {
      if (context.mounted) showAppSnack(context, 'Erro ao criar empresa.');
    }
  }
}

class _CompanyTile extends ConsumerWidget {
  const _CompanyTile({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = switch (company.status) {
      CompanyStatus.active => theme.colorScheme.primary,
      CompanyStatus.suspended => Colors.orange,
      CompanyStatus.cancelled => theme.colorScheme.error,
    };

    return ListTile(
      leading: const Icon(Icons.storefront_rounded),
      title: Text(company.name),
      subtitle: Text(
        'Criada em ${company.createdAt.day.toString().padLeft(2, '0')}/'
        '${company.createdAt.month.toString().padLeft(2, '0')}/'
        '${company.createdAt.year}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusBadge(label: company.status.label, color: color),
          PopupMenuButton<String>(
            onSelected: (action) => _onAction(context, ref, action),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'invite_admin',
                child: Text('Criar administrador'),
              ),
              if (company.status != CompanyStatus.active)
                const PopupMenuItem(value: 'activate', child: Text('Ativar')),
              if (company.status == CompanyStatus.active)
                const PopupMenuItem(value: 'suspend', child: Text('Suspender')),
              if (company.status != CompanyStatus.cancelled)
                const PopupMenuItem(value: 'cancel', child: Text('Cancelar')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final repo = ref.read(companiesRepositoryProvider);

    switch (action) {
      case 'invite_admin':
        await showInviteUserDialog(
          context,
          companyId: company.id,
          role: UserRole.admin,
        );
        return;
      case 'activate':
        await repo.setStatus(company.id, CompanyStatus.active);
      case 'suspend':
        final ok = await confirmAction(
          context,
          title: 'Suspender empresa',
          message:
              'Suspender "${company.name}"? Clientes deixarão de acessar a página das mesas.',
          confirmLabel: 'Suspender',
        );
        if (!ok) return;
        await repo.setStatus(company.id, CompanyStatus.suspended);
      case 'cancel':
        final ok = await confirmAction(
          context,
          title: 'Cancelar empresa',
          message: 'Cancelar "${company.name}"? Esta ação encerra o contrato.',
          confirmLabel: 'Cancelar empresa',
        );
        if (!ok) return;
        await repo.setStatus(company.id, CompanyStatus.cancelled);
    }

    ref.invalidate(allCompaniesProvider);
    ref.invalidate(gtechDashboardStatsProvider);
  }
}
