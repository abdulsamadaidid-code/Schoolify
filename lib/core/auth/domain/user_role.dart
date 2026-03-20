/// Product roles — see repo `docs/product.md`.
///
/// **Dependency:** Authoritative role + `school_id` will come from Auth & tenancy
/// (e.g. `profiles` / `school_members`). Until then, optional stub via user metadata.
enum UserRole {
  admin,
  teacher,
  parent,
}

extension UserRoleX on UserRole {
  String get routePath => switch (this) {
        UserRole.admin => '/admin',
        UserRole.teacher => '/teacher',
        UserRole.parent => '/parent',
      };
}
