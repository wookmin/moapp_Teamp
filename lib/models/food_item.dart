import 'storage_type.dart';

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.expiryDate,
    this.category,
    this.storageType = StorageType.unknown,
  });

  final String id;
  final String name;
  final DateTime expiryDate;
  final String? category;
  final StorageType storageType;

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
    'category': category,
    'storageType': storageType.name,
  };

  factory FoodItem.fromFirestore(String id, Map<String, Object?> data) {
    return FoodItem(
      id: id,
      name: data['name'] as String? ?? '',
      expiryDate: DateTime.parse(data['expiryDate'] as String),
      category: data['category'] as String?,
      storageType: StorageType.fromName(data['storageType'] as String?),
    );
  }
}
