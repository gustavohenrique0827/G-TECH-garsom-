import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../../calls/data/calls_repository.dart';
import '../../../calls/presentation/controllers/calls_controllers.dart';
import '../../domain/entities/table_context.dart';
import '../controllers/client_controllers.dart';

/// The client PWA landing screen — reached exclusively via QR Code or NFC,
/// both encoding the exact same `/r/:companyId/m/:tableId` URL. No login,
/// no account, no order-taking: just "call the waiter", "see the menu",
/// "leave a review".
class ClientTablePage extends ConsumerWidget {
  const ClientTablePage({
    super.key,
    required this.companyId,
    required this.tableId,
  });

  final String companyId;
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (companyId: companyId, tableId: tableId);
    final contextAsync = ref.watch(tableContextProvider(args));

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 460,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: contextAsync.when(
              data: (table) => _ClientContent(table: table),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ClientError(
                onRetry: () => ref.invalidate(tableContextProvider(args)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientError extends StatelessWidget {
  const _ClientError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 40),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Não encontramos esta mesa.\nPeça para o restaurante conferir o QR Code.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _ClientContent extends ConsumerWidget {
  const _ClientContent({required this.table});

  final TableContext table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callsAsync = ref.watch(
      tableCallsProvider((companyId: table.companyId, tableId: table.tableId)),
    );
    final hasActiveCall = callsAsync.valueOrNull?.any((c) => c.isActive) ?? false;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Brand(table: table),
        const SizedBox(height: AppSpacing.xl4),
        Text(
          'Como podemos ajudar?',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl3),
        _CallWaiterCard(table: table, active: hasActiveCall),
        const SizedBox(height: AppSpacing.lg),
        _ActionTile(
          icon: Icons.menu_book_rounded,
          label: 'Cardápio',
          onTap: () => context.push(
            AppRoutes.clientMenuPath(table.companyId, table.tableId),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ActionTile(
          icon: Icons.star_rounded,
          label: 'Avaliar Restaurante',
          onTap: () => _openGoogleReview(context, table.googleReviewUrl),
        ),
      ],
    );
  }

  Future<void> _openGoogleReview(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este restaurante ainda não configurou o link de avaliação.')),
      );
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.table});

  final TableContext table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: table.logoUrl != null
              ? CachedNetworkImageProvider(table.logoUrl!)
              : null,
          child: table.logoUrl == null
              ? Text(
                  table.companyName.isNotEmpty
                      ? table.companyName[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.headlineMedium,
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(table.companyName, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            table.tableLabel,
            style: theme.textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _CallWaiterCard extends ConsumerStatefulWidget {
  const _CallWaiterCard({required this.table, required this.active});

  final TableContext table;
  final bool active;

  @override
  ConsumerState<_CallWaiterCard> createState() => _CallWaiterCardState();
}

class _CallWaiterCardState extends ConsumerState<_CallWaiterCard> {
  bool _sending = false;

  Future<void> _call() async {
    setState(() => _sending = true);
    try {
      await ref.read(callsRepositoryProvider).sendCall(
        companyId: widget.table.companyId,
        tableId: widget.table.tableId,
        tableLabel: widget.table.tableLabel,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.active) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl2),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Garçom chamado!',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Aguarde um momento.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _sending ? null : _call,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            _sending
                ? const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.notifications_active_rounded,
                    size: 40,
                    color: theme.colorScheme.onPrimary,
                  ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chamar Garçom',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
