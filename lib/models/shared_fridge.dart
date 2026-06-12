class SharedFridge {
  const SharedFridge({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final String role;
  final DateTime? createdAt;

  bool get canEdit => role == 'editor';

  factory SharedFridge.fromMembership(String id, Map<String, Object?> data) {
    final createdAt = data['createdAt'];
    return SharedFridge(
      id: id,
      name: data['name'] as String? ?? '친구의 냉장고',
      ownerUid: data['ownerUid'] as String? ?? id,
      role: data['role'] as String? ?? 'viewer',
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}

class SharedFridgeInvite {
  const SharedFridgeInvite({
    required this.ownerUid,
    required this.code,
    required this.fridgeName,
    required this.role,
    required this.expiresAt,
  });

  final String ownerUid;
  final String code;
  final String fridgeName;
  final String role;
  final DateTime expiresAt;

  bool get canEdit => role == 'editor';

  Uri get uri =>
      Uri(scheme: 'jangbogo', host: 'invite', pathSegments: [ownerUid, code]);
}
