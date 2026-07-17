import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/staff_repository.dart';
import '../../domain/entities/staff_member.dart';

final companyStaffProvider =
    FutureProvider.family<List<StaffMember>, String>((ref, companyId) {
      return ref.watch(staffRepositoryProvider).fetchCompanyStaff(companyId);
    });
