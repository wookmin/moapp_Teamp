class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.isGuest = false,
  });

  final String id;
  final String? email;
  final String? displayName;
  final bool isGuest;
}
