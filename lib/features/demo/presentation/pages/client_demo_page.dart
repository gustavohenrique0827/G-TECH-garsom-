import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/chama_garcom_controller.dart';
import '../../state/chama_garcom_models.dart';
import '../../theme/chama_garcom_theme.dart';

class ClientDemoPage extends ConsumerStatefulWidget {
  const ClientDemoPage({super.key});

  @override
  ConsumerState<ClientDemoPage> createState() => _ClientDemoPageState();
}

class _ClientDemoPageState extends ConsumerState<ClientDemoPage> {
  final TextEditingController _tableController = TextEditingController();

  Timer? _bannerTicker;
  Duration _bannerElapsed = Duration.zero;
  bool _showWaterScreen = false;
  int? _bannerCallId;

  @override
  void dispose() {
    _bannerTicker?.cancel();
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChamaGarcomTheme.of(context);
    final state = ref.watch(chamaGarcomControllerProvider);

    const tableNum = 7;
    final tableLabel = 'MESA ${tableNum.toString().padLeft(2, '0')}';

    final hasOpenCall = state.clientOpenCall != null;
    final bannerCall = state.clientOpenCall;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || bannerCall == null) return;

      if (_bannerCallId == bannerCall.id) return;

      _bannerTicker?.cancel();
      _bannerCallId = bannerCall.id;

      _bannerElapsed = DateTime.now().difference(bannerCall.createdAt);

      _bannerTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;

        final state = ref.read(chamaGarcomControllerProvider);

        final currentCall = state.calls.firstWhere(
          (c) => c.id == bannerCall.id,
          orElse: () => bannerCall,
        );

        setState(() {
          _bannerElapsed = DateTime.now().difference(currentCall.createdAt);
        });
      });
    });

    return Scaffold(
      backgroundColor: theme.ink,
      body: Center(
        child: Container(
          alignment: Alignment.topCenter,
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: SizedBox.expand(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: [
                    _buildClientCard(
                      theme,
                      tableLabel,
                      hasOpenCall,
                      bannerCall,
                      _bannerElapsed,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Simulação: toque no sino, escolha o motivo e mude para o App do Garçom para ver o chamado chegando em tempo real.',
                      textAlign: TextAlign.center,
                      style: theme.textDim.copyWith(fontSize: 11.5),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(
    ChamaGarcomTheme theme,
    String tableLabel,
    bool hasOpenCall,
    ChamaCall? bannerCall,
    Duration elapsed,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.ink2, theme.ink],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.line),
      ),
      child: Column(
        children: [
          _BrandRow(theme, tableLabel),
          if (hasOpenCall && bannerCall != null)
            _buildStatusBanner(theme, bannerCall, elapsed),
          const SizedBox(height: 10),
          _Hero(theme),
          const SizedBox(height: 24),
          _BellZone(
            theme: theme,
            enabled: !hasOpenCall,
            onPressed: () {
              if (hasOpenCall) return;
              setState(() => _showWaterScreen = false);
              _openNeedModal(theme);
            },
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: theme.ink3,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.line),
            ),
            child: Row(
              children: [
                Text(
                  'Ver Cardápio',
                  style: theme.paper600.copyWith(fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '→',
                  style: theme.brassBright600.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
    ChamaGarcomTheme theme,
    ChamaCall bannerCall,
    Duration elapsed,
  ) {
    final timerStr = _fmt(elapsed.inSeconds);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18, bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.ink3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: theme.brassBright,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.brassBright.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${bannerCall.reason.sentLabel}\nAguardando garçom...',
              style: theme.textDim.copyWith(fontSize: 13),
            ),
          ),
          Text(
            timerStr,
            style: theme.brassBright600.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _openNeedModal(ChamaGarcomTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.ink2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (_) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _showWaterScreen
              ? _WaterModal(theme: theme, onBack: () {
                  setState(() => _showWaterScreen = false);
                  Navigator.of(context).pop();
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted) _openNeedModal(theme);
                  });
                })
              : _MainNeedModal(
                  theme: theme,
                  onWaterTap: () {
                    setState(() => _showWaterScreen = true);
                    Navigator.of(context).pop();
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) _openNeedModal(theme);
                    });
                  },
                  onSelect: (reason) {
                    Navigator.of(context).pop();
                    ref
                        .read(chamaGarcomControllerProvider.notifier)
                        .clientSendCall(
                          tableNum: 7,
                          reason: reason,
                        );
                  },
                ),
        );
      },
    );
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _MainNeedModal extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final void Function(ChamaReasonKey) onSelect;
  final VoidCallback onWaterTap;

  const _MainNeedModal({
    required this.theme,
    required this.onSelect,
    required this.onWaterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('main'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(theme),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'O que você precisa?',
              style: theme.space600.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mesa 07 · escolha uma opção e o garçom já é avisado',
              style: theme.textDimmer.copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          _ModalOption(
            theme: theme,
            icon: '🍽️',
            title: 'Fazer um pedido',
            desc: 'Quero pedir algo do cardápio',
            onTap: () => onSelect(ChamaReasonKey.pedido),
          ),
          const SizedBox(height: 8),
          _ModalOption(
            theme: theme,
            icon: '💧',
            title: 'Pedir água',
            desc: 'Água com ou sem gás',
            onTap: onWaterTap,
          ),
          const SizedBox(height: 8),
          _ModalOption(
            theme: theme,
            icon: '🧾',
            title: 'Pedir a conta',
            desc: 'Fechar a comanda da mesa',
            onTap: () => onSelect(ChamaReasonKey.conta),
          ),
          const SizedBox(height: 8),
          _ModalOption(
            theme: theme,
            icon: '🔔',
            title: 'Só chamar o garçom',
            desc: 'Outro assunto',
            onTap: () => onSelect(ChamaReasonKey.garcom),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: theme.textDim.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterModal extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final VoidCallback onBack;

  const _WaterModal({
    required this.theme,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('water'),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DragHandle(theme),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '💧 Como você prefere?',
              style: theme.space600.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: 3),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mesa 07 · escolha o tipo de água',
              style: theme.textDimmer.copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          _ModalOption(
            theme: theme,
            icon: '🚰',
            title: 'Sem gás',
            desc: 'Água natural',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
          _ModalOption(
            theme: theme,
            icon: '🫧',
            title: 'Com gás',
            desc: 'Água gaseificada',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onBack,
              child: Text(
                '← Voltar',
                style: theme.textDim.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  final ChamaGarcomTheme theme;

  const _DragHandle(this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: theme.line,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final String tableLabel;

  const _BrandRow(this.theme, this.tableLabel);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.brassBright, theme.brass],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'B',
                style: theme.ink700.copyWith(
                  fontFamily: theme.spaceFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bar do Zé',
                  style: theme.space600.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chama Garçom',
                  style: theme.textDimmer.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: theme.ink3,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.line),
          ),
          child: Text(
            tableLabel,
            style: theme.mono600.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final ChamaGarcomTheme theme;

  const _Hero(this.theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Bem-vindo',
          style: theme.textDimmer.copyWith(
            fontSize: 11,
            letterSpacing: 0.16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: 'Precisa de algo?\n',
            style: theme.space600.copyWith(fontSize: 26),
            children: [
              TextSpan(
                text: 'Toque no sino.',
                style: theme.space600.copyWith(
                  fontSize: 26,
                  color: theme.brassBright,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BellZone extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final bool enabled;
  final VoidCallback onPressed;

  const _BellZone({
    required this.theme,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        GestureDetector(
          onTap: enabled ? onPressed : null,
          child: AnimatedScale(
            scale: enabled ? 1 : 0.98,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: 172,
              height: 172,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [theme.brassBright, theme.brass],
                  center: const Alignment(-0.35, -0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.brass.withOpacity(0.5),
                    blurRadius: 50,
                    spreadRadius: -12,
                    offset: const Offset(0, 20),
                  ),
                ],
                border: Border.all(
                  color: theme.line.withOpacity(0.9),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_active,
                size: 56,
                color: theme.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Chamar Garçom',
          style: theme.space600.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 10),
        Text(
          'Toque para escolher o que você precisa.',
          textAlign: TextAlign.center,
          style: theme.textDimmer.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _ModalOption extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final String icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ModalOption({
    required this.theme,
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: theme.ink3,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.ink,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.line),
              ),
              child: Text(
                icon,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.paper600.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    desc,
                    style: theme.textDimmer.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '→',
              style: theme.textDimmer.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}