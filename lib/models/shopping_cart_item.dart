class ShoppingCartItem {
  const ShoppingCartItem({
    required this.id,
    required this.name,
    required this.note,
    required this.tag,
    required this.isChecked,
    required this.createdAt,
    this.source = 'recommendation',
  });

  final String id;
  final String name;
  final String note;
  final String tag;
  final bool isChecked;
  final DateTime createdAt;
  final String source;

  String get normalizedName => normalizeName(name);

  Map<String, Object?> toFirestore() => {
    'name': name,
    'nameLowercase': normalizedName,
    'note': note,
    'tag': tag,
    'isChecked': isChecked,
    'createdAt': createdAt.toIso8601String(),
    'source': source,
  };

  factory ShoppingCartItem.fromFirestore(String id, Map<String, Object?> data) {
    final createdAtValue = data['createdAt'] as String?;

    return ShoppingCartItem(
      id: id,
      name: data['name'] as String? ?? '',
      note: data['note'] as String? ?? '',
      tag: data['tag'] as String? ?? '',
      isChecked: data['isChecked'] as bool? ?? false,
      createdAt: createdAtValue == null
          ? DateTime.now()
          : DateTime.tryParse(createdAtValue) ?? DateTime.now(),
      source: data['source'] as String? ?? 'recommendation',
    );
  }

  static String normalizeName(String value) => value.trim().toLowerCase();
}
