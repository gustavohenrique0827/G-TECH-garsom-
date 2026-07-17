import 'package:freezed_annotation/freezed_annotation.dart';

part 'menu_item.freezed.dart';

@freezed
class MenuItem with _$MenuItem {
  const factory MenuItem({
    required String id,
    required String categoryId,
    required String name,
    required String? description,
    required num price,
    required String? imageUrl,
    @Default(true) bool isAvailable,
  }) = _MenuItem;

  const MenuItem._();

  factory MenuItem.fromRow(Map<String, dynamic> row) {
    return MenuItem(
      id: row['id'] as String,
      categoryId: row['category_id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      price: row['price'] as num,
      imageUrl: row['image_url'] as String?,
      isAvailable: row['is_available'] as bool? ?? true,
    );
  }
}

@freezed
class MenuCategory with _$MenuCategory {
  const factory MenuCategory({
    required String id,
    required String name,
    required List<MenuItem> items,
  }) = _MenuCategory;
}
