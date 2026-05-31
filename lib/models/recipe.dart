class Recipe {
  const Recipe({
    required this.title,
    required this.summary,
    this.id,
    this.imageUrl,
    this.cookingMethod,
    this.category,
    this.calories,
    this.protein,
    this.fat,
    this.carbohydrate,
    this.sodium,
    this.ingredients = const [],
    this.steps = const [],
  });

  final String title;
  final String summary;
  final String? id;
  final String? imageUrl;
  final String? cookingMethod;
  final String? category;
  final int? calories;
  final double? protein;
  final double? fat;
  final double? carbohydrate;
  final double? sodium;
  final List<String> ingredients;
  final List<String> steps;
}
