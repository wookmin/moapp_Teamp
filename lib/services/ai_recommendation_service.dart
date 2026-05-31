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
          'maxOutputTokens': 512,
        },
      }),
    );

    if (response.statusCode != 200) {
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

    final data = _tryDecodeJsonObject(text);
    if (data == null) {
      return _buildRecommendedRecipe(recipeCandidates.first);
    }

    final selectedIndex = (data['selectedIndex'] as num?)?.toInt() ?? 1;
    final fallbackRecipe =
        recipeCandidates.length >= selectedIndex && selectedIndex > 0
        ? recipeCandidates[selectedIndex - 1]
        : recipeCandidates.first;
    final summary =
        data['summary'] as String? ??
        data['todayMessage'] as String? ??
        fallbackRecipe.summary;

    return _buildRecommendedRecipe(fallbackRecipe, summary: summary);
  }

  Recipe _buildRecommendedRecipe(Recipe fallbackRecipe, {String? summary}) {
    return Recipe(
      id: fallbackRecipe.id,
      title: fallbackRecipe.title,
      summary: summary ?? '소비기한이 임박한 재료와 가장 잘 맞는 공공 레시피를 먼저 추천했어요.',
      imageUrl: fallbackRecipe.imageUrl,
      cookingMethod: fallbackRecipe.cookingMethod,
      category: fallbackRecipe.category,
      calories: fallbackRecipe.calories,
      protein: fallbackRecipe.protein,
      fat: fallbackRecipe.fat,
      carbohydrate: fallbackRecipe.carbohydrate,
      sodium: fallbackRecipe.sodium,
      ingredients: fallbackRecipe.ingredients,
      steps: fallbackRecipe.steps,
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

Gemini의 역할은 후보를 새로 만들거나 조리법을 다시 쓰는 것이 아닙니다.
가장 좋은 후보 번호를 고르고, 사용자에게 보여줄 짧은 추천 이유만 작성하세요.

아래 JSON 형식으로만 응답해주세요. 코드블록이나 다른 텍스트는 포함하지 마세요.
{
  "selectedIndex": 1,
  "summary": "왜 지금 이 레시피가 좋은지 1~2문장, 120자 이내",
  "todayMessage": "오늘의 추천 문구 1문장, 40자 이내"
}
''';
  }

  Map<String, Object?>? _tryDecodeJsonObject(String text) {
    final cleanedText = _stripCodeFence(text);
    final jsonStart = cleanedText.indexOf('{');
    final jsonEnd = cleanedText.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
      return _decodePartialJson(cleanedText);
    }

    final jsonText = cleanedText.substring(jsonStart, jsonEnd + 1);
    try {
      return jsonDecode(jsonText) as Map<String, Object?>;
    } on FormatException {
      return _decodePartialJson(cleanedText);
    }
  }

  String _stripCodeFence(String text) {
    return text
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  Map<String, Object?>? _decodePartialJson(String text) {
    final selectedIndexMatch = RegExp(
      r'"selectedIndex"\s*:\s*(\d+)',
    ).firstMatch(text);
    final summaryMatch = RegExp(
      r'"summary"\s*:\s*"([^"]*)',
      dotAll: true,
    ).firstMatch(text);
    final todayMessageMatch = RegExp(
      r'"todayMessage"\s*:\s*"([^"]*)',
      dotAll: true,
    ).firstMatch(text);

    final summary = summaryMatch?.group(1)?.trim();
    if (selectedIndexMatch == null &&
        (summary == null || summary.isEmpty) &&
        todayMessageMatch == null) {
      return null;
    }

    return {
      if (selectedIndexMatch != null)
        'selectedIndex': int.tryParse(selectedIndexMatch.group(1)!),
      if (summary != null && summary.isNotEmpty) 'summary': summary,
      if (todayMessageMatch?.group(1)?.trim().isNotEmpty ?? false)
        'todayMessage': todayMessageMatch!.group(1)!.trim(),
    };
  }
}
