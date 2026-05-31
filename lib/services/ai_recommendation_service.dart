import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/food_item.dart';
import '../models/price_trend.dart';
import '../models/recipe.dart';

class AiRecommendationService {
  AiRecommendationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _model = 'gemini-2.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  Future<Recipe?> recommendRecipe({
    required List<FoodItem> expiringFoods,
    required List<Recipe> recipeCandidates,
    required List<PriceTrend> priceTrends,
  }) async {
    if (expiringFoods.isEmpty || recipeCandidates.isEmpty) return null;

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    debugPrint(
      '[AI] apiKey: ${apiKey == null ? "null" : (apiKey.isEmpty ? "empty" : "set (${apiKey.length}자)")}',
    );

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('.env에 GEMINI_API_KEY가 설정되지 않았습니다.');
    }

    final prompt = _buildPrompt(
      expiringFoods: expiringFoods,
      recipeCandidates: recipeCandidates,
      priceTrends: priceTrends,
    );

    final response = await _client.post(
      Uri.parse('$_baseUrl?key=$apiKey'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'maxOutputTokens': 2048,
        },
      }),
    );

    debugPrint('[AI] 응답 status: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('[AI] 응답 body: ${response.body}');
      throw Exception('Gemini API 오류 (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, Object?>;
    final candidates = body['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini 응답에 candidates가 없습니다.');
    }

    final content = (candidates.first as Map)['content'] as Map?;
    final parts = content?['parts'] as List?;
    final text = (parts?.first as Map?)?['text'] as String?;
    if (text == null) throw Exception('Gemini 응답 텍스트가 없습니다.');

    final data = _decodeJsonObject(text);
    final fallbackRecipe = recipeCandidates.first;

    return Recipe(
      id: fallbackRecipe.id,
      title: data['title'] as String? ?? fallbackRecipe.title,
      summary: data['summary'] as String? ?? fallbackRecipe.summary,
      imageUrl: fallbackRecipe.imageUrl,
      cookingMethod: fallbackRecipe.cookingMethod,
      category: fallbackRecipe.category,
      calories: fallbackRecipe.calories,
      protein: fallbackRecipe.protein,
      fat: fallbackRecipe.fat,
      carbohydrate: fallbackRecipe.carbohydrate,
      sodium: fallbackRecipe.sodium,
      ingredients:
          (data['ingredients'] as List?)?.cast<String>() ??
          fallbackRecipe.ingredients,
      steps: (data['steps'] as List?)?.cast<String>() ?? fallbackRecipe.steps,
    );
  }

  String _buildPrompt({
    required List<FoodItem> expiringFoods,
    required List<Recipe> recipeCandidates,
    required List<PriceTrend> priceTrends,
  }) {
    final foodList = expiringFoods
        .map((f) => '- ${f.name} (${f.expiryLabel})')
        .join('\n');
    final priceTrendList = priceTrends.isEmpty
        ? '가격 동향 정보 없음'
        : priceTrends
              .map(
                (trend) =>
                    '- ${trend.itemName}: ${trend.trendLabel}, ${trend.recommendationReason}',
              )
              .join('\n');
    final recipeList = recipeCandidates
        .asMap()
        .entries
        .map((entry) {
          final recipe = entry.value;
          return '''
${entry.key + 1}. ${recipe.title}
- 분류: ${recipe.category ?? '정보 없음'}
- 조리법: ${recipe.cookingMethod ?? '정보 없음'}
- 열량: ${recipe.calories?.toString() ?? '정보 없음'} kcal
- 나트륨: ${recipe.sodium?.toString() ?? '정보 없음'} mg
- 재료: ${recipe.ingredients.take(8).join(', ')}
- 조리 순서: ${recipe.steps.take(4).join(' / ')}
''';
        })
        .join('\n');

    return '''
당신은 냉장고 재료 기반 한식 레시피 추천 도우미입니다.
아래 공공 레시피 후보 중에서만 1개를 골라 추천해주세요. 후보에 없는 새 레시피를 만들면 안 됩니다.

냉장고 재료:
$foodList

KAMIS 가격 동향:
$priceTrendList

공공 레시피 후보:
$recipeList

아래 JSON 형식으로만 응답해주세요. 코드블록이나 다른 텍스트는 포함하지 마세요.
{
  "title": "선택한 후보 레시피 이름",
  "summary": "왜 지금 이 레시피가 좋은지 2~3문장. 임박 재료, 가격 동향, 조리 난이도, 영양정보 중 근거를 포함.",
  "ingredients": ["후보 레시피의 주요 재료"],
  "steps": ["후보 레시피의 핵심 조리 순서"]
}
''';
  }

  Map<String, Object?> _decodeJsonObject(String text) {
    final cleanedText = _stripCodeFence(text);
    final jsonStart = cleanedText.indexOf('{');
    final jsonEnd = cleanedText.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      throw Exception('JSON 파싱 실패: $cleanedText');
    }

    return jsonDecode(cleanedText.substring(jsonStart, jsonEnd + 1))
        as Map<String, Object?>;
  }

  String _stripCodeFence(String text) {
    return text
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
}
