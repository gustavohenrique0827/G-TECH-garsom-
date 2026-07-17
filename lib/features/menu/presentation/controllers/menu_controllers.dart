import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/menu_repository.dart';
import '../../domain/entities/menu_item.dart';

final companyMenuProvider = FutureProvider.family<List<MenuCategory>, String>((
  ref,
  companyId,
) {
  return ref.watch(menuRepositoryProvider).fetchMenu(companyId);
});
