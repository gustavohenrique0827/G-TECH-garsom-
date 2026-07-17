/// Mirrors the Postgres enum `public.user_role`.
enum UserRole {
  masterAdmin,
  admin,
  waiter;

  static UserRole fromDb(String value) {
    return switch (value) {
      'master_admin' => UserRole.masterAdmin,
      'admin' => UserRole.admin,
      'waiter' => UserRole.waiter,
      _ => throw ArgumentError('Unknown user_role: $value'),
    };
  }

  String get toDb {
    return switch (this) {
      UserRole.masterAdmin => 'master_admin',
      UserRole.admin => 'admin',
      UserRole.waiter => 'waiter',
    };
  }

  /// Landing route right after login, once the role is known.
  String get homePath {
    return switch (this) {
      UserRole.masterAdmin => '/gtech',
      UserRole.admin => '/admin',
      UserRole.waiter => '/garcom',
    };
  }
}
