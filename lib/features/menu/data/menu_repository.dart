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

  /// Public read-only menu — categories with their available items,
  /// already ordered. The client only ever consults this; there is no
  /// online ordering flow.
  Future<List<MenuCategory>> fetchMenu(String companyId) async {
    final rows = await _client
        .from('menu_categories')
        .select('id, name, menu_items(id, category_id, name, description, price, image_url, is_available, position)')
        .eq('company_id', companyId)
        .order('position');

    return (rows as List).map((row) {
      final items = (row['menu_items'] as List).cast<Map<String, dynamic>>()
          .where((item) => item['is_available'] as bool? ?? true)
          .toList()
        ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

      return MenuCategory(
        id: row['id'] as String,
        name: row['name'] as String,
        items: items.map(MenuItem.fromRow).toList(),
      );
    }).toList();
  }
}
