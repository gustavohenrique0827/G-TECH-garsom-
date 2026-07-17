import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/companies_repository.dart';
import '../../domain/entities/company.dart';

final companyByIdProvider = FutureProvider.family<Company, String>((
  ref,
  id,
) {
  return ref.watch(companiesRepositoryProvider).fetchById(id);
});

final allCompaniesProvider = FutureProvider<List<Company>>((ref) {
  return ref.watch(companiesRepositoryProvider).fetchAll();
});
