import 'package:flutter/material.dart';

class ChamaReason {
  final ChamaReasonKey key;
  final String sentLabel;
  final String icon;
  final String label;

  const ChamaReason({
    required this.key,
    required this.sentLabel,
    required this.icon,
    required this.label,
  });
}

enum ChamaReasonKey { pedido, aguaSem, aguaCom, conta, garcom }

extension ChamaReasonExt on ChamaReasonKey {
  ChamaReason get data {
    switch (this) {
      case ChamaReasonKey.pedido:
        return const ChamaReason(
          key: ChamaReasonKey.pedido,
          icon: '🍽️',
          label: 'Fazer um pedido',
          sentLabel: 'Pedido solicitado.',
        );
      case ChamaReasonKey.aguaSem:
        return const ChamaReason(
          key: ChamaReasonKey.aguaSem,
          icon: '🚰',
          label: 'Água sem gás',
          sentLabel: 'Água sem gás solicitada.',
        );
      case ChamaReasonKey.aguaCom:
        return const ChamaReason(
          key: ChamaReasonKey.aguaCom,
          icon: '🫧',
          label: 'Água com gás',
          sentLabel: 'Água com gás solicitada.',
        );
      case ChamaReasonKey.conta:
        return const ChamaReason(
          key: ChamaReasonKey.conta,
          icon: '🧾',
          label: 'Pedir a conta',
          sentLabel: 'Conta solicitada.',
        );
      case ChamaReasonKey.garcom:
      default:
        return const ChamaReason(
          key: ChamaReasonKey.garcom,
          icon: '🔔',
          label: 'Chamar garçom',
          sentLabel: 'Chamado enviado.',
        );
    }
  }
}

class ChamaCall {
  final int id;
  final int table;
  final DateTime createdAt;
  final ChamaReason reason;
  final CallStatus status;
  final DateTime? acceptedAt;

  const ChamaCall({
    required this.id,
    required this.table,
    required this.createdAt,
    required this.reason,
    required this.status,
    required this.acceptedAt,
  });

  ChamaCall copyWith({
    CallStatus? status,
    DateTime? acceptedAt,
  }) {
    return ChamaCall(
      id: id,
      table: table,
      createdAt: createdAt,
      reason: reason,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}

enum CallStatus { pending, accepted }

class ChamaGarcomState {
  final List<ChamaCall> calls;
  final int doneToday;
  final ChamaCall? clientOpenCall;

  const ChamaGarcomState({
    required this.calls,
    required this.doneToday,
    required this.clientOpenCall,
  });

  factory ChamaGarcomState.initial() =>
      const ChamaGarcomState(calls: [], doneToday: 0, clientOpenCall: null);

  ChamaGarcomState copyWith({
    List<ChamaCall>? calls,
    int? doneToday,
    ChamaCall? clientOpenCall,
  }) {
    return ChamaGarcomState(
      calls: calls ?? this.calls,
      doneToday: doneToday ?? this.doneToday,
      clientOpenCall: clientOpenCall,
    );
  }
}

