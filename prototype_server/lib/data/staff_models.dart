/// The Crown Solar Teams officer who raised a request for a partner
/// (specs/013-teams-support, CSE-2 and CSE-3).
///
/// Only the name and role the partner sees; the staff id stays in the
/// database. Absent — not empty — when the partner raised it themselves.
class RaisedByRow {
  const RaisedByRow({required this.name, required this.role});

  final String name;

  /// 'mo' | 'asm'.
  final String role;

  Map<String, Object?> toJson() => {'name': name, 'role': role};

  /// Reads the `raised_by_staff_*` columns; null when no officer raised it.
  static RaisedByRow? fromColumns(Map<String, dynamic> row) {
    final name = row['raised_by_staff_name'] as String?;
    final role = row['raised_by_staff_role'] as String?;
    if (name == null || role == null) return null;
    return RaisedByRow(name: name, role: role);
  }
}
