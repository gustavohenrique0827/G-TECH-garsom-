import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/empty_state.dart';
import '../../../../shared/utils/dialogs.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../menu/data/menu_repository.dart';
import '../../../menu/domain/entities/menu_item.dart';
import '../../../menu/presentation/controllers/menu_controllers.dart';
import '../widgets/admin_scaffold.dart';

class AdminMenuPage extends ConsumerWidget {
  const AdminMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;

    return AdminScaffold(
      title: 'Cardápio',
      currentIndex: 2,
      floatingActionButton: companyId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createCategory(context, ref, companyId),
              icon: const Icon(Icons.add),
              label: const Text('Nova categoria'),
            ),
      body: companyId == null
          ? const SizedBox.shrink()
          : _MenuAdminList(companyId: companyId),
    );
  }

  Future<void> _createCategory(
    BuildContext context,
    WidgetRef ref,
    String companyId,
  ) async {
    final name = await promptText(
      context,
      title: 'Nova categoria',
      label: 'Nome (ex: Bebidas)',
      confirmLabel: 'Criar',
    );
    if (name == null) return;
    await ref
        .read(menuRepositoryProvider)
        .createCategory(companyId: companyId, name: name);
    ref.invalidate(companyMenuAdminProvider(companyId));
  }
}

class _MenuAdminList extends ConsumerWidget {
  const _MenuAdminList({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(companyMenuAdminProvider(companyId));

    return menuAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar o cardápio.',
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Cardápio vazio.',
            subtitle: 'Crie uma categoria para começar.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            96,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: Text(
                              category.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Adicionar item',
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () => _createItem(context, ref, category.id),
                        ),
                        IconButton(
                          tooltip: 'Excluir categoria',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _deleteCategory(context, ref, category),
                        ),
                      ],
                    ),
                    if (category.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text(
                          'Nenhum item nesta categoria.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ...category.items.map(
                      (item) => _ItemTile(companyId: companyId, item: item),
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

  Future<void> _createItem(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
  ) async {
    final result = await showDialog<({String name, String? desc, num price})>(
      context: context,
      builder: (context) => const _NewItemDialog(),
    );
    if (result == null) return;

    await ref.read(menuRepositoryProvider).createItem(
      categoryId: categoryId,
      companyId: companyId,
      name: result.name,
      description: result.desc,
      price: result.price,
    );
    ref.invalidate(companyMenuAdminProvider(companyId));
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    MenuCategory category,
  ) async {
    final ok = await confirmAction(
      context,
      title: 'Excluir categoria',
      message:
          'Excluir "${category.name}" e todos os seus ${category.items.length} itens?',
      confirmLabel: 'Excluir',
    );
    if (!ok) return;
    await ref.read(menuRepositoryProvider).deleteCategory(category.id);
    ref.invalidate(companyMenuAdminProvider(companyId));
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.companyId, required this.item});

  final String companyId;
  final MenuItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final repo = ref.read(menuRepositoryProvider);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      title: Text(item.name),
      subtitle: item.description == null ? null : Text(item.description!),
      leading: Text(
        currency.format(item.price),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: item.isAvailable,
            onChanged: (value) async {
              await repo.setItemAvailability(id: item.id, isAvailable: value);
              ref.invalidate(companyMenuAdminProvider(companyId));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Excluir item',
                message: 'Excluir "${item.name}"?',
                confirmLabel: 'Excluir',
              );
              if (!ok) return;
              await repo.deleteItem(item.id);
              ref.invalidate(companyMenuAdminProvider(companyId));
            },
          ),
        ],
      ),
    );
  }
}

class _NewItemDialog extends StatefulWidget {
  const _NewItemDialog();

  @override
  State<_NewItemDialog> createState() => _NewItemDialogState();
}

class _NewItemDialogState extends State<_NewItemDialog> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final price = num.tryParse(_price.text.replaceAll(',', '.'));
    if (name.isEmpty || price == null) return;
    Navigator.of(context).pop((
      name: name,
      desc: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      price: price,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _desc,
            decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Preço (ex: 14,90)'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Criar')),
      ],
    );
  }
}
