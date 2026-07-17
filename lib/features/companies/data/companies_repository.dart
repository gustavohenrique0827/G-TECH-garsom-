import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/company.dart';

final companiesRepositoryProvider = Provider<CompaniesRepository>((ref) {
  return CompaniesRepository(ref.watch(supabaseClientProvider));
});

class CompaniesRepository {
  CompaniesRepository(this._client);

  final SupabaseClient _client;

  Future<Company> fetchById(String id) async {
    final row = await _client.from('companies').select().eq('id', id).single();
    return Company.fromRow(row);
  }

  /// GTech-only — RLS restricts this to `master_admin` (see migration 0001).
  Future<List<Company>> fetchAll() async {
    final rows = await _client
        .from('companies')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Company.fromRow(row)).toList();
  }

  /// GTech-only (RLS).
  Future<Company> createCompany({required String name}) async {
    final row = await _client
        .from('companies')
        .insert({'name': name, 'slug': _slugify(name)})
        .select()
        .single();
    return Company.fromRow(row);
  }

  /// GTech-only in practice: RLS lets an admin update their own row, but a
  /// DB trigger (migration 0003) rejects status changes from non-masters.
  Future<void> setStatus(String id, CompanyStatus status) async {
    await _client
        .from('companies')
        .update({'status': status.name})
        .eq('id', id);
  }

  /// Own-company settings update (admin) — name, review link, logo.
  Future<void> updateCompany(
    String id, {
    String? name,
    String? googleReviewUrl,
    String? logoUrl,
  }) async {
    await _client.from('companies').update({
      'name': ?name,
      'google_review_url': ?googleReviewUrl,
      'logo_url': ?logoUrl,
    }).eq('id', id);
  }

  /// name → url-safe slug, plus a short random suffix so two "Bar do Zé"
  /// registrations never collide on the unique constraint.
  String _slugify(String name) {
    const from = 'àáâãäçèéêëìíîïñòóôõöùúûü';
    const to = 'aaaaaceeeeiiiinooooouuuu';
    var slug = name.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      slug = slug.replaceAll(from[i], to[i]);
    }
    slug = slug
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return '$slug-$suffix';
  }
}
