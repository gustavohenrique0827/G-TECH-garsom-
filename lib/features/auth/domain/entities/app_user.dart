import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_role.dart';

part 'app_user.freezed.dart';

/// The authenticated user, resolved from Supabase Auth + `public.profiles`.
///
/// [companyId] is null only for [UserRole.masterAdmin] — every admin/waiter
/// belongs to exactly one company.
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
    required String? companyId,
    String? avatarUrl,
  }) = _AppUser;

  const AppUser._();

  factory AppUser.fromProfileRow(
    Map<String, dynamic> row, {
    required String email,
  }) {
    return AppUser(
      id: row['id'] as String,
      email: email,
      fullName: row['full_name'] as String? ?? '',
      role: UserRole.fromDb(row['role'] as String),
      companyId: row['company_id'] as String?,
      avatarUrl: row['avatar_url'] as String?,
    );
  }
}
