import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/config/env.dart';

part 'restaurant_table.freezed.dart';

@freezed
class RestaurantTable with _$RestaurantTable {
  const factory RestaurantTable({
    required String id,
    required String companyId,
    required String label,
  }) = _RestaurantTable;

  const RestaurantTable._();

  /// The one canonical client URL for this table. QR codes and NFC tags
  /// both encode exactly this — there is deliberately no NFC-specific
  /// variant anywhere in the system.
  String get clientUrl => '${Env.clientBaseUrl}/r/$companyId/m/$id';

  factory RestaurantTable.fromRow(Map<String, dynamic> row) {
    return RestaurantTable(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      label: row['label'] as String,
    );
  }
}
