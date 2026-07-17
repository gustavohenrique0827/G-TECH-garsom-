import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../shared/utils/dialogs.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../data/staff_repository.dart';
import '../controllers/staff_controllers.dart';

/// Shared account-creation dialog: the restaurant admin uses it to add
/// waiters; GTech uses it to add a company's admin. The server-side
/// `invite-user` function is what actually enforces who may create whom.
Future<void> showInviteUserDialog(
  BuildContext context, {
  required String companyId,
  required UserRole role,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _InviteUserDialog(companyId: companyId, role: role),
  );
}

class _InviteUserDialog extends ConsumerStatefulWidget {
  const _InviteUserDialog({required this.companyId, required this.role});

  final String companyId;
  final UserRole role;

  @override
  ConsumerState<_InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<_InviteUserDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty || !email.contains('@') || password.length < 8) {
      showAppSnack(
        context,
        'Preencha nome, e-mail válido e senha com 8+ caracteres.',
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(staffRepositoryProvider).inviteUser(
        email: email,
        password: password,
        fullName: name,
        role: widget.role,
        companyId: widget.companyId,
      );
      ref.invalidate(companyStaffProvider(widget.companyId));
      if (mounted) {
        Navigator.of(context).pop();
        showAppSnack(context, 'Usuário criado com sucesso.');
      }
    } on Failure catch (failure) {
      if (mounted) {
        setState(() => _sending = false);
        showAppSnack(
          context,
          failure.maybeWhen(
            validation: (message) => message ?? 'Erro ao criar usuário.',
            orElse: () => 'Erro ao criar usuário.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (widget.role) {
      UserRole.admin => 'administrador',
      UserRole.waiter => 'garçom',
      UserRole.masterAdmin => 'master admin',
    };

    return AlertDialog(
      title: Text('Novo $roleLabel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome completo'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Senha inicial (8+ caracteres)',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }
}
