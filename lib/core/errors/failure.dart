import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Typed application failure, surfaced by repositories instead of raw
/// exceptions so the presentation layer never depends on Supabase/Postgrest
/// error shapes directly.
@freezed
class Failure with _$Failure {
  const factory Failure.network([String? message]) = NetworkFailure;
  const factory Failure.auth([String? message]) = AuthFailure;
  const factory Failure.notFound([String? message]) = NotFoundFailure;
  const factory Failure.validation([String? message]) = ValidationFailure;
  const factory Failure.unknown([String? message]) = UnknownFailure;
}
