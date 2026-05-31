class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.expiryDate,
  });

  final String id;
  final String name;
  final DateTime expiryDate;

  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;

  bool get isUrgent => daysLeft <= 2;

  String get expiryLabel {
    if (daysLeft < 0) return '${-daysLeft}일 초과';
    if (daysLeft == 0) return '오늘 만료';
    return '$daysLeft일 남음';
  }

  String get statusLabel {
    if (daysLeft < 0) return '기한 만료';
    if (daysLeft <= 2) return '임박';
    if (daysLeft <= 7) return '보통';
    return '양호';
  }

  Map<String, Object?> toFirestore() => {
        'name': name,
        'expiryDate': expiryDate.toIso8601String(),
      };

  factory FoodItem.fromFirestore(String id, Map<String, Object?> data) {
    return FoodItem(
      id: id,
      name: data['name'] as String? ?? '',
      expiryDate: DateTime.parse(data['expiryDate'] as String),
    );
  }
}
