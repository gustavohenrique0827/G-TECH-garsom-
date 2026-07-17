import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/client_repository.dart';
import '../../domain/entities/table_context.dart';

typedef TableRef = ({String companyId, String tableId});

final tableContextProvider = FutureProvider.family<TableContext, TableRef>((
  ref,
  args,
) {
  return ref
      .watch(clientRepositoryProvider)
      .fetchTableContext(companyId: args.companyId, tableId: args.tableId);
});
