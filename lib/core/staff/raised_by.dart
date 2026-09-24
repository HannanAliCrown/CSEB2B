/// The Crown Solar Teams officer who raised a request for this partner
/// (specs/013-teams-support, CSE-2 and CSE-3).
///
/// Absent when the partner raised it themselves; the screens show a
/// "Raised by" row only when there is one.
class RaisedBy {
  const RaisedBy({required this.name, required this.role});

  final String name;

  /// 'mo' | 'asm'.
  final String role;

  String get roleLabel => staffRoleLabel(role);

  static RaisedBy? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final name = json['name'] as String?;
    final role = json['role'] as String?;
    if (name == null || role == null) return null;
    return RaisedBy(name: name, role: role);
  }
}

/// How a Crown Solar Teams role is named to a partner.
String staffRoleLabel(String? role) => switch (role) {
  'mo' => 'Marketing Officer',
  'asm' => 'Area Sales Manager',
  'rsm' => 'Regional Sales Manager',
  _ => '',
};
