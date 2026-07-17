import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/user_role.dart';

part 'staff_member.freezed.dart';

/// A company staff row as seen by whoever manages it (restaurant admin or
/// GTech) — a projection of `profiles`.
@freezed
class StaffMember with _$StaffMember {
  const factory StaffMember({
    required String id,
    required String fullName,
    required String email,
    required UserRole role,
  }) = _StaffMember;

  const StaffMember._();

  factory StaffMember.fromRow(Map<String, dynamic> row) {
    return StaffMember(
      id: row['id'] as String,
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      role: UserRole.fromDb(row['role'] as String),
    );
  }
}
