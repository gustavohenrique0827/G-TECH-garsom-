import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_record.freezed.dart';

/// A single "chamar garçom" event — one button, one tap, one row. There is
/// no reason picker and no accept/finish state machine by design (see
/// spec): a call is simply considered *active* while it's within
/// [CallRecord.activeWindow] of `createdAt`; the waiter queue and the
/// client's "already called" cooldown both derive from that same rule.
@freezed
class CallRecord with _$CallRecord {
  const factory CallRecord({
    required String id,
    required String companyId,
    required String tableId,
    required String tableLabel,
    required DateTime createdAt,
  }) = _CallRecord;

  const CallRecord._();

  static const activeWindow = Duration(minutes: 10);

  bool get isActive => DateTime.now().difference(createdAt) < activeWindow;

  /// [tableLabel] is denormalized onto the row at insert time — Supabase's
  /// realtime `.stream()` API can't express joins, so the label snapshot
  /// travels with the call itself instead of requiring a second query.
  factory CallRecord.fromRow(Map<String, dynamic> row) {
    return CallRecord(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      tableId: row['table_id'] as String,
      tableLabel: row['table_label'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
