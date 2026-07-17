import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/company.dart';

final companiesRepositoryProvider = Provider<CompaniesRepository>((ref) {
  return CompaniesRepository(ref.watch(supabaseClientProvider));
});

class CompaniesRepository {
  CompaniesRepository(this._client);

  final SupabaseClient _client;

  Future<Company> fetchById(String id) async {
    final row = await _client.from('companies').select().eq('id', id).single();
    return Company.fromRow(row);
  }

  /// GTech-only — RLS restricts this to `master_admin` (see migration 0001).
  Future<List<Company>> fetchAll() async {
    final rows = await _client
        .from('companies')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Company.fromRow(row)).toList();
  }
}
