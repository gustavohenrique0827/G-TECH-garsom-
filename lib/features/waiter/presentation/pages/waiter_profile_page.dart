import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../companies/presentation/controllers/companies_controllers.dart';
import '../widgets/waiter_scaffold.dart';

class WaiterProfilePage extends ConsumerWidget {
  const WaiterProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);

    return WaiterScaffold(
      title: 'Perfil',
      currentIndex: 2,
      body: user == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(user.fullName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(user.email, style: theme.textTheme.bodyMedium),
                  if (user.companyId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Consumer(
                      builder: (context, ref, _) {
                        final company = ref.watch(companyByIdProvider(user.companyId!));
                        return Text(
                          company.valueOrNull?.name ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                  const Spacer(),
                  PrimaryButton(
                    label: 'Sair',
                    icon: Icons.logout_rounded,
                    onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
    );
  }
}
