import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/empty_state.dart';
import '../../../../design_system/widgets/status_badge.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../staff/presentation/controllers/staff_controllers.dart';
import '../../../staff/presentation/widgets/invite_user_dialog.dart';
import '../widgets/admin_scaffold.dart';

class AdminWaitersPage extends ConsumerWidget {
  const AdminWaitersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;

    return AdminScaffold(
      title: 'Garçons',
      currentIndex: 3,
      floatingActionButton: companyId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showInviteUserDialog(
                context,
                companyId: companyId,
                role: UserRole.waiter,
              ),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Novo garçom'),
            ),
      body: companyId == null
          ? const SizedBox.shrink()
          : _StaffList(companyId: companyId),
    );
  }
}

class _StaffList extends ConsumerWidget {
  const _StaffList({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(companyStaffProvider(companyId));
    final theme = Theme.of(context);

    return staffAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar a equipe.',
      ),
      data: (staff) {
        if (staff.isEmpty) {
          return const EmptyState(
            icon: Icons.badge_outlined,
            title: 'Nenhum membro na equipe ainda.',
            subtitle: 'Adicione o primeiro garçom pelo botão abaixo.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: staff.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final member = staff[i];
            final isWaiter = member.role == UserRole.waiter;
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    member.fullName.isNotEmpty
                        ? member.fullName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(member.fullName),
                subtitle: Text(member.email),
                trailing: StatusBadge(
                  label: isWaiter ? 'Garçom' : 'Admin',
                  color: isWaiter
                      ? theme.colorScheme.primary
                      : theme.colorScheme.tertiary,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
