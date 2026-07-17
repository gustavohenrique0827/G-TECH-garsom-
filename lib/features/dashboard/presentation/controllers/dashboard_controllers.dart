import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dashboard_repository.dart';
import '../../domain/entities/dashboard_stats.dart';

final adminDashboardStatsProvider =
    FutureProvider.family<AdminDashboardStats, String>((ref, companyId) {
      return ref.watch(dashboardRepositoryProvider).fetchAdminStats(companyId);
    });

final gtechDashboardStatsProvider = FutureProvider<GtechDashboardStats>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchGtechStats();
});
