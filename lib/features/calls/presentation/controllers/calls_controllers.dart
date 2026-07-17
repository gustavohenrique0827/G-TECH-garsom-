import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/calls_repository.dart';
import '../../domain/entities/call_record.dart';

/// All calls for a company, newest first — waiter queue filters this to
/// [CallRecord.isActive]; the history tab shows it unfiltered.
final companyCallsProvider = StreamProvider.family<List<CallRecord>, String>((
  ref,
  companyId,
) {
  return ref.watch(callsRepositoryProvider).watchCompanyCalls(companyId);
});

typedef TableCallsArgs = ({String companyId, String tableId});

/// Calls for a single table — the client screen uses this to know whether
/// an active call already exists (bell disabled during the cooldown).
final tableCallsProvider =
    StreamProvider.family<List<CallRecord>, TableCallsArgs>((ref, args) {
      return ref
          .watch(callsRepositoryProvider)
          .watchTableCalls(companyId: args.companyId, tableId: args.tableId);
    });
