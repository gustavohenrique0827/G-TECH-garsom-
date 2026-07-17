import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase/supabase_providers.dart';
import '../domain/entities/menu_item.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(ref.watch(supabaseClientProvider));
});

class MenuRepository {
  MenuRepository(this._client);

  final SupabaseClient _client;

  static const _selectMenu =
      'id, name, menu_items(id, category_id, name, description, price, image_url, is_available, position)';

  /// Public read-only menu — categories with their available items,
  /// already ordered. The client only ever consults this; there is no
  /// online ordering flow.
  Future<List<MenuCategory>> fetchMenu(String companyId) =>
      _fetch(companyId, onlyAvailable: true);

  /// Admin view — includes unavailable items so they can be re-enabled.
  Future<List<MenuCategory>> fetchMenuAdmin(String companyId) =>
      _fetch(companyId, onlyAvailable: false);

  Future<List<MenuCategory>> _fetch(
    String companyId, {
    required bool onlyAvailable,
  }) async {
    final rows = await _client
        .from('menu_categories')
        .select(_selectMenu)
        .eq('company_id', companyId)
        .order('position');

    return (rows as List).map((row) {
      final items = (row['menu_items'] as List)
          .cast<Map<String, dynamic>>()
          .where((item) => !onlyAvailable || (item['is_available'] as bool? ?? true))
          .toList()
        ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

      return MenuCategory(
        id: row['id'] as String,
        name: row['name'] as String,
        items: items.map(MenuItem.fromRow).toList(),
      );
    }).toList();
  }

  Future<void> createCategory({
    required String companyId,
    required String name,
  }) async {
    await _client.from('menu_categories').insert({
      'company_id': companyId,
      'name': name,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('menu_categories').delete().eq('id', id);
  }

  Future<void> createItem({
    required String categoryId,
    required String companyId,
    required String name,
    String? description,
    required num price,
  }) async {
    await _client.from('menu_items').insert({
      'category_id': categoryId,
      'company_id': companyId,
      'name': name,
      'description': description,
      'price': price,
    });
  }

  Future<void> setItemAvailability({
    required String id,
    required bool isAvailable,
  }) async {
    await _client
        .from('menu_items')
        .update({'is_available': isAvailable})
        .eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await _client.from('menu_items').delete().eq('id', id);
  }
}
