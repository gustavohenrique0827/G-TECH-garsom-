import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/dashboard_stats.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(supabaseClientProvider));
});

class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient _client;

  Future<AdminDashboardStats> fetchAdminStats(String companyId) async {
    final startOfDay = _startOfLocalDayUtc(DateTime.now());

    final tables = await _client
        .from('restaurant_tables')
        .select()
        .eq('company_id', companyId)
        .count(CountOption.exact);

    final waiters = await _client
        .from('profiles')
        .select()
        .eq('company_id', companyId)
        .eq('role', 'waiter')
        .count(CountOption.exact);

    final calls = await _client
        .from('calls')
        .select()
        .eq('company_id', companyId)
        .gte('created_at', startOfDay.toIso8601String())
        .count(CountOption.exact);

    return AdminDashboardStats(
      tablesCount: tables.count,
      waitersCount: waiters.count,
      callsToday: calls.count,
    );
  }

  Future<GtechDashboardStats> fetchGtechStats() async {
    final startOfDay = _startOfLocalDayUtc(DateTime.now());

    final companies = await _client.from('companies').select().count(CountOption.exact);
    final active = await _client
        .from('companies')
        .select()
        .eq('status', 'active')
        .count(CountOption.exact);
    final calls = await _client
        .from('calls')
        .select()
        .gte('created_at', startOfDay.toIso8601String())
        .count(CountOption.exact);

    return GtechDashboardStats(
      companiesCount: companies.count,
      activeCompaniesCount: active.count,
      callsToday: calls.count,
    );
  }

  DateTime _startOfLocalDayUtc(DateTime now) {
    final local = now.toLocal();
    return DateTime(local.year, local.month, local.day).toUtc();
  }
}
