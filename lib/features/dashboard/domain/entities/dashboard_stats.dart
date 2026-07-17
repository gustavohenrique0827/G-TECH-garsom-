import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_stats.freezed.dart';

@freezed
class AdminDashboardStats with _$AdminDashboardStats {
  const factory AdminDashboardStats({
    required int tablesCount,
    required int waitersCount,
    required int callsToday,
  }) = _AdminDashboardStats;
}

@freezed
class GtechDashboardStats with _$GtechDashboardStats {
  const factory GtechDashboardStats({
    required int companiesCount,
    required int activeCompaniesCount,
    required int callsToday,
  }) = _GtechDashboardStats;
}
