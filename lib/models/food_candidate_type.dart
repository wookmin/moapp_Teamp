enum FoodCandidateType {
  fridge,
  freezer,
  pantry,
  nonFood,
  unknown;

  String get label {
    switch (this) {
      case FoodCandidateType.fridge:
        return '냉장 후보';
      case FoodCandidateType.freezer:
        return '냉동 후보';
      case FoodCandidateType.pantry:
        return '실온 식품';
      case FoodCandidateType.nonFood:
        return '비식품';
      case FoodCandidateType.unknown:
        return '확인 필요';
    }
  }

  bool get isDefaultSelected {
    return this == FoodCandidateType.fridge ||
        this == FoodCandidateType.freezer;
  }
}
