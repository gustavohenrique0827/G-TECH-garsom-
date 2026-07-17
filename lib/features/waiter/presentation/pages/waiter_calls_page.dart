import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/empty_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../calls/domain/entities/call_record.dart';
import '../../../calls/presentation/controllers/calls_controllers.dart';
import '../widgets/waiter_scaffold.dart';

/// Receive-only call queue. By design there is no Accept / Reject /
/// Finish action here — the waiter receives the notification, sees the
/// table, and walks over. The call simply ages out of the active window
/// on its own (see [CallRecord.activeWindow]).
class WaiterCallsPage extends ConsumerWidget {
  const WaiterCallsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;

    return WaiterScaffold(
      title: 'Chamadas',
      currentIndex: 0,
      body: companyId == null
          ? const SizedBox.shrink()
          : _CallsList(companyId: companyId),
    );
  }
}

class _CallsList extends ConsumerWidget {
  const _CallsList({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callsAsync = ref.watch(companyCallsProvider(companyId));

    return callsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar as chamadas.',
      ),
      data: (calls) {
        final active = calls.where((c) => c.isActive).toList();

        if (active.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'Nenhum chamado no momento.',
            subtitle: 'Tudo tranquilo por aqui.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: active.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => _CallCard(call: active[i]),
        );
      },
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({required this.call});

  final CallRecord call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waited = DateTime.now().difference(call.createdAt);
    final urgent = waited.inMinutes >= 3;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: urgent
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.table_bar_rounded,
                color: urgent ? theme.colorScheme.onErrorContainer : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(call.tableLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Aguardando há ${waited.inMinutes} min',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: urgent ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                      fontWeight: urgent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
