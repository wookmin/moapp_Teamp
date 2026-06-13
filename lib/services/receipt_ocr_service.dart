import 'package:flutter/services.dart';

import '../models/recognized_food_item.dart';
import 'food_item_recognition_service.dart';

class ReceiptOcrService {
  static const _channel = MethodChannel('teamproject/receipt_ocr');

  ReceiptOcrService({
    this._recognitionService = const FoodItemRecognitionService(),
  });

  final FoodItemRecognitionService _recognitionService;

  Future<List<RecognizedFoodItem>> recognizeImage(String imagePath) async {
    final text = await _channel.invokeMethod<String>('recognizeReceipt', {
      'path': imagePath,
    });
    return parseReceiptText(text ?? '');
  }

  List<RecognizedFoodItem> parseReceiptText(String text) {
    final names = _extractItemNames(text);
    final items = <RecognizedFoodItem>[];
    final recognizedNames = <String>{};

    for (final name in names) {
      final item = _recognitionService.recognizeReceiptItem(name);
      if (recognizedNames.add(item.name)) {
        items.add(item);
      }
    }

    return items;
  }

  List<String> _extractItemNames(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final numberedNames = <String>[];
    final presetNames = <String>[];

    for (final line in lines) {
      final numbered = RegExp(r'^\d{3}\s*(.+)$').firstMatch(line);
      final candidate = _cleanItemName(numbered?.group(1) ?? line);
      if (!_isLikelyItemName(candidate)) continue;

      final hasPreset = _recognitionService.findPreset(candidate) != null;
      if (numbered != null && RegExp(r'[가-힣]').hasMatch(candidate)) {
        if (!numberedNames.contains(candidate)) {
          numberedNames.add(candidate);
        }
      } else if (hasPreset && !presetNames.contains(candidate)) {
        presetNames.add(candidate);
      }
    }

    return [...numberedNames, ...presetNames];
  }

  String _cleanItemName(String value) {
    return value
        .replaceFirst(RegExp(r'^[*·\-]+\s*'), '')
        .replaceAll(
          RegExp(r'\s+\d{1,3}(?:,\d{3})+\s+\d+\s+\d{1,3}(?:,\d{3})+$'),
          '',
        )
        .trim();
  }

  bool _isLikelyItemName(String value) {
    if (value.length < 2 || !RegExp(r'[가-힣]').hasMatch(value)) {
      return false;
    }

    const excludedTerms = [
      '상품코드',
      '면세',
      '과세',
      '합계',
      '포인트',
      '카드',
      '거래정보',
      '캐셔',
      '대표',
      '주소',
      '구매',
    ];
    return !excludedTerms.any(value.contains);
  }
}
