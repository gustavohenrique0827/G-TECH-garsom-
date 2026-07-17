import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tables_repository.dart';
import '../../domain/entities/restaurant_table.dart';

final companyTablesProvider =
    FutureProvider.family<List<RestaurantTable>, String>((ref, companyId) {
      return ref.watch(tablesRepositoryProvider).fetchTables(companyId);
    });
