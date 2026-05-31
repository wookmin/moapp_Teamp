enum StorageType {
  fridge,
  freezer,
  pantry,
  unknown;

  String get label {
    switch (this) {
      case StorageType.fridge:
        return '냉장';
      case StorageType.freezer:
        return '냉동';
      case StorageType.pantry:
        return '실온';
      case StorageType.unknown:
        return '확인 필요';
    }
  }

  static StorageType fromName(String? name) {
    return StorageType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => StorageType.unknown,
    );
  }
}
