import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/restaurant_table.dart';

final tablesRepositoryProvider = Provider<TablesRepository>((ref) {
  return TablesRepository(ref.watch(supabaseClientProvider));
});

class TablesRepository {
  TablesRepository(this._client);

  final SupabaseClient _client;

  Future<List<RestaurantTable>> fetchTables(String companyId) async {
    final rows = await _client
        .from('restaurant_tables')
        .select()
        .eq('company_id', companyId)
        .order('label');
    return (rows as List)
        .map((row) => RestaurantTable.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTable({
    required String companyId,
    required String label,
  }) async {
    await _client.from('restaurant_tables').insert({
      'company_id': companyId,
      'label': label,
    });
  }

  Future<void> renameTable({required String id, required String label}) async {
    await _client.from('restaurant_tables').update({'label': label}).eq('id', id);
  }

  Future<void> deleteTable(String id) async {
    await _client.from('restaurant_tables').delete().eq('id', id);
  }
}
