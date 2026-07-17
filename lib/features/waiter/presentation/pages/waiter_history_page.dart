import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/empty_state.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../calls/presentation/controllers/calls_controllers.dart';
import '../widgets/waiter_scaffold.dart';

class WaiterHistoryPage extends ConsumerWidget {
  const WaiterHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;
    final dateFormat = DateFormat('dd/MM • HH:mm');

    return WaiterScaffold(
      title: 'Histórico',
      currentIndex: 1,
      body: companyId == null
          ? const SizedBox.shrink()
          : ref
                .watch(companyCallsProvider(companyId))
                .when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Não foi possível carregar o histórico.',
                  ),
                  data: (calls) {
                    if (calls.isEmpty) {
                      return const EmptyState(
                        icon: Icons.history_rounded,
                        title: 'Nenhuma chamada registrada ainda.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: calls.length,
                      separatorBuilder: (_, _) => const Divider(height: AppSpacing.xl2),
                      itemBuilder: (context, i) {
                        final call = calls[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.table_bar_rounded),
                          title: Text(call.tableLabel),
                          trailing: Text(dateFormat.format(call.createdAt)),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
