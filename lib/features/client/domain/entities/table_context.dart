import 'package:freezed_annotation/freezed_annotation.dart';

part 'table_context.freezed.dart';

/// Everything the client PWA needs about the restaurant + table it landed
/// on, resolved from the `/r/:companyId/m/:tableId` URL — the same URL for
/// both QR Code and NFC, so this is the single lookup both paths share.
@freezed
class TableContext with _$TableContext {
  const factory TableContext({
    required String companyId,
    required String companyName,
    required String? logoUrl,
    required String? googleReviewUrl,
    required String tableId,
    required String tableLabel,
  }) = _TableContext;

  const TableContext._();

  factory TableContext.fromRow(Map<String, dynamic> row) {
    final company = row['companies'] as Map<String, dynamic>;
    return TableContext(
      companyId: company['id'] as String,
      companyName: company['name'] as String,
      logoUrl: company['logo_url'] as String?,
      googleReviewUrl: company['google_review_url'] as String?,
      tableId: row['id'] as String,
      tableLabel: row['label'] as String,
    );
  }
}
