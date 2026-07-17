import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failure.dart';
import '../../../services/supabase/supabase_providers.dart';
import '../../auth/domain/entities/user_role.dart';
import '../domain/entities/staff_member.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(supabaseClientProvider));
});

class StaffRepository {
  StaffRepository(this._client);

  final SupabaseClient _client;

  Future<List<StaffMember>> fetchCompanyStaff(String companyId) async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name, email, role')
        .eq('company_id', companyId)
        .order('full_name');
    return (rows as List)
        .map((row) => StaffMember.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Creates a staff account via the `invite-user` Edge Function — the only
  /// path that holds the service role. Who may create what is enforced
  /// server-side (master_admin → admin/waiter anywhere; admin → waiter in
  /// their own company), not here.
  Future<void> inviteUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String companyId,
  }) async {
    try {
      await _client.functions.invoke(
        'invite-user',
        body: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'role': role.toDb,
          'company_id': companyId,
        },
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map<String, dynamic>
          ? details['error'] as String?
          : null;
      throw Failure.validation(message ?? 'Não foi possível criar o usuário.');
    }
  }
}
