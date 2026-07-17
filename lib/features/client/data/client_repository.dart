import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/table_context.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(supabaseClientProvider));
});

/// Public, unauthenticated reads for the client PWA. Every query here runs
/// under the `anon` role — RLS (not app logic) is what keeps one company
/// from ever seeing another's data.
class ClientRepository {
  ClientRepository(this._client);

  final SupabaseClient _client;

  Future<TableContext> fetchTableContext({
    required String companyId,
    required String tableId,
  }) async {
    try {
      final row = await _client
          .from('restaurant_tables')
          .select('id, label, companies!inner(id, name, logo_url, google_review_url)')
          .eq('id', tableId)
          .eq('company_id', companyId)
          .single();

      return TableContext.fromRow(row);
    } on PostgrestException catch (e) {
      throw Failure.notFound(e.message);
    }
  }
}
