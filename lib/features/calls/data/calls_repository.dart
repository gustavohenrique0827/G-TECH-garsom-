import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/call_record.dart';

final callsRepositoryProvider = Provider<CallsRepository>((ref) {
  return CallsRepository(ref.watch(supabaseClientProvider));
});

class CallsRepository {
  CallsRepository(this._client);

  final SupabaseClient _client;

  /// Creates a call. Silently allowed by RLS only when the caller is the
  /// anonymous client role and the table belongs to [companyId] — see
  /// migration 0001, policy `calls_insert_public`.
  Future<void> sendCall({
    required String companyId,
    required String tableId,
    required String tableLabel,
  }) async {
    await _client.from('calls').insert({
      'company_id': companyId,
      'table_id': tableId,
      'table_label': tableLabel,
    });
  }

  /// Realtime stream of every call for one table, newest first — used by
  /// the client screen to know whether the "chamar garçom" bell should be
  /// disabled (an active call already exists for this table).
  Stream<List<CallRecord>> watchTableCalls({
    required String companyId,
    required String tableId,
  }) {
    return _client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('table_id', tableId)
        .order('created_at')
        .map((rows) => rows.map(CallRecord.fromRow).toList());
  }

  /// Realtime stream of every call for a company, newest first — the
  /// waiter's queue is just this list filtered client-side to
  /// [CallRecord.isActive]; "Histórico" is the same stream, unfiltered.
  Stream<List<CallRecord>> watchCompanyCalls(String companyId) {
    return _client
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('company_id', companyId)
        .order('created_at')
        .map((rows) => rows.map(CallRecord.fromRow).toList().reversed.toList());
  }
}
