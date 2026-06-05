import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';

class RecipeApiService {
  RecipeApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://openapi.foodsafetykorea.go.kr/api';

  Future<List<Recipe>> fetchRecipesByIngredients(
    List<String> ingredients, {
    int limitPerIngredient = 8,
  }) async {
    final apiKey =
        dotenv.env['FOODSAFETY_API_KEY']?.trim() ??
        dotenv.env['MFDS_RECIPE_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      return const [];
    }

    final recipesByTitle = <String, Recipe>{};
    final uniqueIngredients = ingredients
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toSet()
        .take(5);

    for (final ingredient in uniqueIngredients) {
      final recipes = await _fetchByIngredient(
        apiKey: apiKey,
        ingredient: ingredient,
        limit: limitPerIngredient,
      );

      for (final recipe in recipes) {
        recipesByTitle.putIfAbsent(recipe.title, () => recipe);
      }
    }

    return recipesByTitle.values.toList();
  }

  Future<List<Recipe>> _fetchByIngredient({
    required String apiKey,
    required String ingredient,
    required int limit,
  }) async {
    final encodedIngredient = Uri.encodeComponent(ingredient);
    final uri = Uri.parse(
      '$_baseUrl/$apiKey/COOKRCP01/json/1/$limit/RCP_PARTS_DTLS=$encodedIngredient',
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      return const [];
    }

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final service = body['COOKRCP01'] as Map<String, Object?>?;
    final rows = service?['row'] as List?;

    if (rows == null || rows.isEmpty) {
      return const [];
    }

    return rows
        .whereType<Map>()
        .map((row) => _mapRecipe(row.cast<String, Object?>()))
        .toList();
  }

  Recipe _mapRecipe(Map<String, Object?> row) {
    final steps = <String>[];
    for (var index = 1; index <= 20; index += 1) {
      final key = 'MANUAL${index.toString().padLeft(2, '0')}';
      final value = (row[key] as String?)?.trim();
      if (value != null && value.isNotEmpty) {
        steps.add(value);
      }
    }

    return Recipe(
      id: row['RCP_SEQ'] as String?,
      title: row['RCP_NM'] as String? ?? '이름 없는 레시피',
      summary: row['RCP_NA_TIP'] as String? ?? '',
      imageUrl: row['ATT_FILE_NO_MAIN'] as String?,
      cookingMethod: row['RCP_WAY2'] as String?,
      category: row['RCP_PAT2'] as String?,
      calories: _parseInt(row['INFO_ENG']),
      carbohydrate: _parseDouble(row['INFO_CAR']),
      protein: _parseDouble(row['INFO_PRO']),
      fat: _parseDouble(row['INFO_FAT']),
      sodium: _parseDouble(row['INFO_NA']),
      ingredients: _splitIngredients(row['RCP_PARTS_DTLS'] as String?),
      steps: steps,
    );
  }

  List<String> _splitIngredients(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const [];
    }

    return value
        .split(RegExp(r'[,·\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(12)
        .toList();
  }

  int? _parseInt(Object? value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9]'), ''));
  }

  double? _parseDouble(Object? value) {
    if (value == null) {
      return null;
    }

    return double.tryParse(value.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
  }
}
