import 'food_candidate_type.dart';
import 'storage_type.dart';

class FoodShelfLifePreset {
  const FoodShelfLifePreset({
    required this.name,
    required this.category,
    required this.storageType,
    required this.defaultDays,
    this.candidateType,
    this.keywords = const [],
    this.note,
  });

  final String name;
  final String category;
  final StorageType storageType;
  final int defaultDays;
  final FoodCandidateType? candidateType;
  final List<String> keywords;
  final String? note;

  FoodCandidateType get resolvedCandidateType {
    if (candidateType != null) {
      return candidateType!;
    }

    switch (storageType) {
      case StorageType.fridge:
        return FoodCandidateType.fridge;
      case StorageType.freezer:
        return FoodCandidateType.freezer;
      case StorageType.pantry:
        return FoodCandidateType.pantry;
      case StorageType.unknown:
        return FoodCandidateType.unknown;
    }
  }
}
