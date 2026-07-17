import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/primary_button.dart';
import '../../../../shared/utils/dialogs.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../companies/data/companies_repository.dart';
import '../../../companies/presentation/controllers/companies_controllers.dart';
import '../widgets/admin_scaffold.dart';

class AdminSettingsPage extends ConsumerWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final companyId = user?.companyId;

    return AdminScaffold(
      title: 'Configurações',
      currentIndex: 4,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
      body: companyId == null
          ? const SizedBox.shrink()
          : ref
                .watch(companyByIdProvider(companyId))
                .when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Center(child: Text('Não foi possível carregar.')),
                  data: (company) => _SettingsForm(
                    companyId: companyId,
                    initialName: company.name,
                    initialReviewUrl: company.googleReviewUrl ?? '',
                    initialLogoUrl: company.logoUrl ?? '',
                  ),
                ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({
    required this.companyId,
    required this.initialName,
    required this.initialReviewUrl,
    required this.initialLogoUrl,
  });

  final String companyId;
  final String initialName;
  final String initialReviewUrl;
  final String initialLogoUrl;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _reviewUrl = TextEditingController(text: widget.initialReviewUrl);
  late final _logoUrl = TextEditingController(text: widget.initialLogoUrl);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _reviewUrl.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showAppSnack(context, 'O nome do restaurante é obrigatório.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(companiesRepositoryProvider).updateCompany(
        widget.companyId,
        name: _name.text.trim(),
        googleReviewUrl: _reviewUrl.text.trim(),
        logoUrl: _logoUrl.text.trim(),
      );
      ref.invalidate(companyByIdProvider(widget.companyId));
      if (mounted) showAppSnack(context, 'Configurações salvas.');
    } catch (_) {
      if (mounted) showAppSnack(context, 'Erro ao salvar.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ResponsiveCenter(
        maxWidth: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restaurante', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome do restaurante'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _logoUrl,
              decoration: const InputDecoration(
                labelText: 'URL do logo',
                helperText: 'Upload de imagem chega na próxima fase — por enquanto, cole uma URL pública.',
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'Google Meu Negócio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _reviewUrl,
              decoration: const InputDecoration(
                labelText: 'Link de avaliação',
                helperText:
                    'O botão "Avaliar Restaurante" do cliente abre exatamente este link.',
              ),
            ),
            const SizedBox(height: AppSpacing.xl3),
            PrimaryButton(label: 'Salvar', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
