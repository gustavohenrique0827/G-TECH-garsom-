import 'package:freezed_annotation/freezed_annotation.dart';

part 'company.freezed.dart';

enum CompanyStatus {
  active,
  suspended,
  cancelled;

  static CompanyStatus fromDb(String value) {
    return switch (value) {
      'active' => CompanyStatus.active,
      'suspended' => CompanyStatus.suspended,
      'cancelled' => CompanyStatus.cancelled,
      _ => throw ArgumentError('Unknown company status: $value'),
    };
  }

  String get label {
    return switch (this) {
      CompanyStatus.active => 'Ativa',
      CompanyStatus.suspended => 'Suspensa',
      CompanyStatus.cancelled => 'Cancelada',
    };
  }
}

@freezed
class Company with _$Company {
  const factory Company({
    required String id,
    required String name,
    required String? logoUrl,
    required String? googleReviewUrl,
    required CompanyStatus status,
    required DateTime createdAt,
  }) = _Company;

  const Company._();

  factory Company.fromRow(Map<String, dynamic> row) {
    return Company(
      id: row['id'] as String,
      name: row['name'] as String,
      logoUrl: row['logo_url'] as String?,
      googleReviewUrl: row['google_review_url'] as String?,
      status: CompanyStatus.fromDb(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }
}
