import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/empty_state.dart';
import '../../../../shared/utils/dialogs.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../tables/data/tables_repository.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../../../tables/presentation/controllers/tables_controllers.dart';
import '../widgets/admin_scaffold.dart';

/// Table management. Each table's QR dialog shows the one canonical client
/// URL — printed QR codes and NFC tags must both encode exactly it.
class AdminTablesPage extends ConsumerWidget {
  const AdminTablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;

    return AdminScaffold(
      title: 'Mesas',
      currentIndex: 1,
      floatingActionButton: companyId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createTable(context, ref, companyId),
              icon: const Icon(Icons.add),
              label: const Text('Nova mesa'),
            ),
      body: companyId == null
          ? const SizedBox.shrink()
          : _TablesList(companyId: companyId),
    );
  }

  Future<void> _createTable(
    BuildContext context,
    WidgetRef ref,
    String companyId,
  ) async {
    final label = await promptText(
      context,
      title: 'Nova mesa',
      label: 'Identificação (ex: Mesa 12)',
      confirmLabel: 'Criar',
    );
    if (label == null) return;

    try {
      await ref
          .read(tablesRepositoryProvider)
          .createTable(companyId: companyId, label: label);
      ref.invalidate(companyTablesProvider(companyId));
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, 'Não foi possível criar a mesa (nome já usado?).');
      }
    }
  }
}

class _TablesList extends ConsumerWidget {
  const _TablesList({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(companyTablesProvider(companyId));

    return tablesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar as mesas.',
      ),
      data: (tables) {
        if (tables.isEmpty) {
          return const EmptyState(
            icon: Icons.table_bar_outlined,
            title: 'Nenhuma mesa cadastrada.',
            subtitle: 'Crie a primeira mesa para gerar seu QR Code.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: tables.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final table = tables[i];
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.table_bar_rounded),
                title: Text(table.label),
                subtitle: Text(
                  table.clientUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'QR Code',
                      icon: const Icon(Icons.qr_code_2_rounded),
                      onPressed: () => _showQr(context, table),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) => _onAction(context, ref, table, action),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Renomear')),
                        PopupMenuItem(value: 'delete', child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQr(BuildContext context, RestaurantTable table) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(table.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: QrImageView(
                data: table.clientUrl,
                size: 220,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SelectableText(
              table.clientUrl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Grave esta mesma URL na Tag NFC da mesa.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar URL'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: table.clientUrl));
              showAppSnack(context, 'URL copiada.');
            },
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable table,
    String action,
  ) async {
    final repo = ref.read(tablesRepositoryProvider);

    switch (action) {
      case 'rename':
        final label = await promptText(
          context,
          title: 'Renomear mesa',
          label: 'Identificação',
          initialValue: table.label,
        );
        if (label == null) return;
        await repo.renameTable(id: table.id, label: label);
      case 'delete':
        final ok = await confirmAction(
          context,
          title: 'Excluir mesa',
          message:
              'Excluir "${table.label}"? O QR Code impresso desta mesa deixará de funcionar.',
          confirmLabel: 'Excluir',
        );
        if (!ok) return;
        await repo.deleteTable(table.id);
    }

    ref.invalidate(companyTablesProvider(companyId));
  }
}
