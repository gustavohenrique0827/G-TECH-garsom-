import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/chama_garcom_controller.dart';
import '../../state/chama_garcom_models.dart';
import '../../theme/chama_garcom_theme.dart';

import 'package:google_fonts/google_fonts.dart';

class WaiterDemoPage extends ConsumerStatefulWidget {
  const WaiterDemoPage({super.key});

  @override
  ConsumerState<WaiterDemoPage> createState() => _WaiterDemoPageState();
}

class _WaiterDemoPageState extends ConsumerState<WaiterDemoPage> {
  @override
  Widget build(BuildContext context) {
    final theme = ChamaGarcomTheme.of(context);
    final state = ref.watch(chamaGarcomControllerProvider);

    final pending = state.calls.where((c) => c.status == CallStatus.pending).toList();
    final accepted = state.calls.where((c) => c.status == CallStatus.accepted).toList();

    // ordenação por createdAt (HTML)
    final sorted = [...state.calls]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      backgroundColor: theme.ink,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SafeArea(
            child: SizedBox(
              height: double.infinity,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      decoration: BoxDecoration(
                        color: theme.ink2,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: theme.line),
                      ),
                      child: Column(
                        children: [
                          _Header(theme: theme),
                          _Summary(theme: theme, pending: pending.length, accepted: accepted.length, done: state.doneToday),
                          _Queue(theme: theme, calls: sorted),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            child: Text(
                              'Os chamados aparecem em tempo real, ordenados por tempo de espera. Aceite e depois finalize o atendimento.',
                              textAlign: TextAlign.center,
                              style: theme.textDimmer.copyWith(fontSize: 11.5),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ChamaGarcomTheme theme;
  const _Header({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3A4152), Color(0xFF252A36)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.line),
                ),
                alignment: Alignment.center,
                child: Text('JP', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14, color: theme.paper)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('João Pedro', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14, color: theme.paper)),
                  const SizedBox(height: 3),
                  Text('Garçom · Salão 1', style: theme.textDimmer.copyWith(fontSize: 11)),
                ],
              )
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: theme.teal, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Online', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: theme.teal)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final int pending;
  final int accepted;
  final int done;

  const _Summary({required this.theme, required this.pending, required this.accepted, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          _SumCard(theme: theme, value: pending, label: 'Aguardando', brass: true),
          const SizedBox(width: 10),
          _SumCard(theme: theme, value: accepted, label: 'Em atendimento', brass: false),
          const SizedBox(width: 10),
          _SumCard(theme: theme, value: done, label: 'Hoje', brass: false),
        ],
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final int value;
  final String label;
  final bool brass;

  const _SumCard({required this.theme, required this.value, required this.label, required this.brass});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.ink3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: brass ? theme.brassBright : theme.paper,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                	color: theme.textDimmer.color,
                	letterSpacing: 0.06,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  final ChamaGarcomTheme theme;
  final List<ChamaCall> calls;

  const _Queue({required this.theme, required this.calls});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text('Fila de chamados',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.textDimmer.color,

                  letterSpacing: 0.12,
                  decoration: TextDecoration.none,
                )),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: ListView.builder(
                itemCount: calls.length,
                itemBuilder: (context, i) {
                  final c = calls[i];
                  final waitSec = DateTime.now().difference(c.createdAt).inSeconds;
                  final urgent = c.status == CallStatus.pending && waitSec > 90;

                  if (c.status == CallStatus.pending) {
                    return _CallCardPending(
                      theme: theme,
                      call: c,
                      urgent: urgent,
                      onAccept: () => ref.read(chamaGarcomControllerProvider.notifier).acceptCall(c.id),
                    );
                  }

                  final acceptedSec = c.acceptedAt == null
                      ? 0
                      : DateTime.now().difference(c.acceptedAt!).inSeconds;

                  return _CallCardAccepted(
                    theme: theme,
                    call: c,
                    acceptedSec: acceptedSec,
                    onFinish: () => ref.read(chamaGarcomControllerProvider.notifier).finishCall(c.id),
                  );
                },
              ),
            ),
          ),
          if (calls.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      color: Colors.white.withOpacity(0.7),
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nenhum chamado no momento.\nTudo tranquilo por aqui.',
                      textAlign: TextAlign.center,
                      style: theme.textDimmer.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CallCardPending extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final ChamaCall call;
  final bool urgent;
  final VoidCallback onAccept;

  const _CallCardPending({required this.theme, required this.call, required this.urgent, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      // Otimização: Usar um key garante que o widget seja reconstruído corretamente
      key: ValueKey(call.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.ink3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: urgent ? theme.coral.withOpacity(0.35) : theme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.ink,
              border: Border.all(color: theme.line),
            ),
            alignment: Alignment.center,
            child: Text('M${call.table}',
                style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600, color: theme.brassBright)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${call.reason.icon} ${call.reason.label} · Mesa ${call.table}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: theme.paper)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Aguardando', style: theme.textDimmer.copyWith(fontSize: 11.5)),
                    const SizedBox(width: 4),
                    _LiveTimerText(
                      startTime: call.createdAt,
                      style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600),
                      urgent: urgent,
                    ),
                  ],
                )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.brass,
              foregroundColor: theme.ink,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Aceitar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }
}

class _CallCardAccepted extends StatelessWidget {
  final ChamaGarcomTheme theme;
  final ChamaCall call;
  final int acceptedSec;
  final VoidCallback onFinish;

  const _CallCardAccepted({required this.theme, required this.call, required this.acceptedSec, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      // Otimização: Usar um key garante que o widget seja reconstruído corretamente
      key: ValueKey(call.id),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.ink3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.teal.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.ink,
              border: Border.all(color: theme.line),
            ),
            alignment: Alignment.center,
            child: Text('M${call.table}',
                style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600, color: theme.brassBright)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${call.reason.icon} ${call.reason.label} · Mesa ${call.table}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: theme.paper)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Text('● Em atendimento',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: theme.teal,
                            letterSpacing: 0.05,
                          )),
                    ),
                    const SizedBox(width: 6),
                    _LiveTimerText(
                      startTime: call.acceptedAt!,
                      style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.teal.withOpacity(0.14),
              foregroundColor: theme.teal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Finalizar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }
}

/// Um widget que exibe um contador de tempo que atualiza a cada segundo.
class _LiveTimerText extends StatefulWidget {
  final DateTime startTime;
  final TextStyle? style;
  final bool urgent;

  const _LiveTimerText({
    required this.startTime,
    this.style,
    this.urgent = false,
  });

  @override
  State<_LiveTimerText> createState() => _LiveTimerTextState();
}

class _LiveTimerTextState extends State<_LiveTimerText> {
  Timer? _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChamaGarcomTheme.of(context);
    final sec = _elapsed.inSeconds;
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');

    return Text('$m:$s', style: widget.style?.copyWith(color: widget.urgent ? theme.coral : theme.brassBright));
  }
}
