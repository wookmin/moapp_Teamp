import 'food_candidate_type.dart';
import 'storage_type.dart';

class RecognizedFoodItem {
  const RecognizedFoodItem({
    required this.rawName,
    required this.name,
    required this.category,
    required this.storageType,
    required this.candidateType,
    required this.suggestedExpiryDate,
    required this.isSelected,
    this.confidence = 1,
    this.note,
  });

  final String rawName;
  final String name;
  final String category;
  final StorageType storageType;
  final FoodCandidateType candidateType;
  final DateTime suggestedExpiryDate;
  final bool isSelected;
  final double confidence;
  final String? note;

  RecognizedFoodItem copyWith({
    String? rawName,
    String? name,
    String? category,
    StorageType? storageType,
    FoodCandidateType? candidateType,
    DateTime? suggestedExpiryDate,
    bool? isSelected,
    double? confidence,
    String? note,
  }) {
    return RecognizedFoodItem(
      rawName: rawName ?? this.rawName,
      name: name ?? this.name,
      category: category ?? this.category,
      storageType: storageType ?? this.storageType,
      candidateType: candidateType ?? this.candidateType,
      suggestedExpiryDate: suggestedExpiryDate ?? this.suggestedExpiryDate,
      isSelected: isSelected ?? this.isSelected,
      confidence: confidence ?? this.confidence,
      note: note ?? this.note,
    );
  }
}
