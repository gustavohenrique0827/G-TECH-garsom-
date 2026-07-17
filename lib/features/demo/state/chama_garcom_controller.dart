import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chama_garcom_models.dart';

class ChamaGarcomController extends StateNotifier<ChamaGarcomState> {
  ChamaGarcomController() : super(ChamaGarcomState.initial());

  int _nextId = 1;

  // Cliente
  void clientSendCall({
    required int tableNum,
    required ChamaReasonKey reason,
  }) {
    if (state.clientOpenCall != null) return;

    final call = ChamaCall(
      id: _nextId++,
      table: tableNum,
      createdAt: DateTime.now(),
      reason: reason.data,
      status: CallStatus.pending,
      acceptedAt: null,
    );

    state = state.copyWith(
      calls: [...state.calls, call],
      clientOpenCall: call,
    );
  }

  // Garçom
  void acceptCall(int id) {
    final c = state.calls.where((x) => x.id == id).firstOrNull;
    if (c == null) return;
    if (c.status == CallStatus.accepted) return;

    final updated = c.copyWith(
      status: CallStatus.accepted,
      acceptedAt: DateTime.now(),
    );

    state = state.copyWith(
      calls: state.calls.map((x) => x.id == id ? updated : x).toList(),
    );
  }

  void finishCall(int id) {
    final c = state.calls.where((x) => x.id == id).firstOrNull;
    if (c == null) return;

    state = state.copyWith(
      calls: state.calls.where((x) => x.id != id).toList(),
      doneToday: state.doneToday + 1,
      clientOpenCall: state.clientOpenCall?.id == id ? null : state.clientOpenCall,
    );
  }

  // Helpers
  // (simulação opcional no futuro)
}

extension _ListFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

final chamaGarcomControllerProvider = StateNotifierProvider<ChamaGarcomController, ChamaGarcomState>(
  (ref) => ChamaGarcomController(),
);

