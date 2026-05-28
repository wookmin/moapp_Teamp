class ProfileData {
  const ProfileData({
    required this.name,
    required this.subtitle,
    required this.freshnessScore,
    this.badges = const [],
    this.menuItems = const [],
  });

  final String name;
  final String subtitle;
  final int freshnessScore;
  final List<String> badges;
  final List<ProfileMenuItem> menuItems;

  bool get hasConnectedData =>
      name.isNotEmpty ||
      subtitle.isNotEmpty ||
      freshnessScore > 0 ||
      menuItems.isNotEmpty;
}

class ProfileMenuItem {
  const ProfileMenuItem({
    required this.title,
    required this.actionKey,
    this.isDestructive = false,
  });

  final String title;
  final String actionKey;
  final bool isDestructive;
}
