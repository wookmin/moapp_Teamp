import '../data/food_shelf_life_presets.dart';
import '../models/food_candidate_type.dart';
import '../models/food_shelf_life_preset.dart';
import '../models/recognized_food_item.dart';
import '../models/storage_type.dart';

class FoodItemRecognitionService {
  const FoodItemRecognitionService();

  RecognizedFoodItem recognizeManualInput(String rawName) {
    return recognize(rawName, assumeFoodWhenUnknown: true);
  }

  RecognizedFoodItem recognizeReceiptItem(String rawName) {
    return recognize(rawName);
  }

  RecognizedFoodItem recognize(
    String rawName, {
    bool assumeFoodWhenUnknown = false,
  }) {
    final trimmedName = rawName.trim();
    final preset = findPreset(trimmedName);
    final now = DateTime.now();

    if (preset == null) {
      final candidateType = assumeFoodWhenUnknown
          ? FoodCandidateType.fridge
          : FoodCandidateType.unknown;
      return RecognizedFoodItem(
        rawName: trimmedName,
        name: trimmedName,
        category: assumeFoodWhenUnknown ? '직접 입력' : '확인 필요',
        storageType: assumeFoodWhenUnknown
            ? StorageType.fridge
            : StorageType.unknown,
        candidateType: candidateType,
        suggestedExpiryDate: now.add(const Duration(days: 7)),
        isSelected: candidateType.isDefaultSelected,
        confidence: assumeFoodWhenUnknown ? 0.7 : 0.35,
        note: assumeFoodWhenUnknown
            ? '직접 입력한 품목이라 냉장 7일 후로 제안했어요.'
            : '냉장고 품목인지 확인이 필요해요.',
      );
    }

    final candidateType = preset.resolvedCandidateType;
    return RecognizedFoodItem(
      rawName: trimmedName,
      name: preset.name,
      category: preset.category,
      storageType: preset.storageType,
      candidateType: candidateType,
      suggestedExpiryDate: now.add(Duration(days: preset.defaultDays)),
      isSelected: candidateType.isDefaultSelected,
      confidence: 0.9,
      note: preset.note,
    );
  }

  FoodShelfLifePreset? findPreset(String rawName) {
    final normalizedRawName = _normalize(rawName);

    for (final preset in foodShelfLifePresets) {
      final names = [preset.name, ...preset.keywords];
      for (final name in names) {
        final normalizedName = _normalize(name);
        if (normalizedRawName.contains(normalizedName) ||
            normalizedName.contains(normalizedRawName)) {
          return preset;
        }
      }
    }

    return null;
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'[\s\d·.,/()\[\]-]'), '').toLowerCase();
  }
}
