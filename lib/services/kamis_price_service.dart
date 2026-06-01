import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/price_trend.dart';

class KamisPriceService {
  KamisPriceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'www.kamis.or.kr';
  static const _path = '/service/price/xml.do';

  Future<List<PriceTrend>> fetchPriceTrends() async {
    final apiKey = dotenv.env['KAMIS_API_KEY']?.trim();
    final apiId = dotenv.env['KAMIS_API_ID']?.trim();

    if (apiKey == null || apiKey.isEmpty || apiId == null || apiId.isEmpty) {
      return const [];
    }

    final uri = Uri.https(_host, _path, {
      'action': 'dailySalesList',
      'p_cert_key': apiKey,
      'p_cert_id': apiId,
      'p_returntype': 'json',
    });

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return const [];
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final rows = _extractPriceRows(decoded);
      final trends = rows.map(_parseTrend).whereType<PriceTrend>().toList()
        ..sort((a, b) {
          final aDropRank = a.isPriceDrop ? 0 : 1;
          final bDropRank = b.isPriceDrop ? 0 : 1;
          if (aDropRank != bDropRank) return aDropRank.compareTo(bDropRank);
          return (b.changeRate ?? 0).abs().compareTo((a.changeRate ?? 0).abs());
        });

      return trends.take(20).toList();
    } on FormatException {
      return const [];
    } on http.ClientException {
      return const [];
    }
  }

  List<Map<String, Object?>> _extractPriceRows(Object? value) {
    final rows = <Map<String, Object?>>[];

    void visit(Object? node) {
      if (node is Map) {
        final normalized = node.map(
          (key, value) => MapEntry(key.toString(), value as Object?),
        );
        final hasItemName =
            normalized.containsKey('item_name') ||
            normalized.containsKey('productName');
        final hasPrice = normalized.containsKey('dpr1');
        if (hasItemName && hasPrice) {
          rows.add(normalized);
        }

        for (final child in normalized.values) {
          visit(child);
        }
      } else if (node is List) {
        for (final child in node) {
          visit(child);
        }
      }
    }

    visit(value);
    return rows;
  }

  PriceTrend? _parseTrend(Map<String, Object?> row) {
    final productClassCode = _stringValue(row['product_cls_code']);
    if (productClassCode != null && productClassCode != '01') return null;

    final itemName = _normalizeItemName(
      _stringValue(row['item_name'] ?? row['productName']),
    );
    if (itemName == null || itemName.isEmpty) return null;

    final currentPrice = _priceValue(row['dpr1']);
    final previousDayPrice = _priceValue(row['dpr2']);
    final previousMonthPrice = _priceValue(row['dpr3']);
    final previousYearPrice = _priceValue(row['dpr4']);
    final direction = _stringValue(row['direction']);
    final changeRate = _doubleValue(row['value']);
    final unit = _stringValue(row['unit']);
    final trendLabel = _trendLabel(direction, changeRate);
    final priceLabel = currentPrice == null
        ? '가격 정보 확인'
        : '${_formatPrice(currentPrice)}원${unit == null ? '' : ' / $unit'}';

    return PriceTrend(
      itemName: itemName,
      trendLabel: trendLabel,
      recommendationReason: '$priceLabel, KAMIS 최근 가격 기준 $trendLabel 품목입니다.',
      unit: unit,
      currentPrice: currentPrice,
      previousDayPrice: previousDayPrice,
      previousMonthPrice: previousMonthPrice,
      previousYearPrice: previousYearPrice,
      changeRate: changeRate,
    );
  }

  String _trendLabel(String? direction, double? changeRate) {
    final rateText = changeRate == null
        ? ''
        : ' ${changeRate.toStringAsFixed(1)}%';
    return switch (direction) {
      '0' => '가격 하락$rateText',
      '1' => '가격 상승$rateText',
      '2' => '가격 보합',
      _ => '가격 동향 확인',
    };
  }

  String? _stringValue(Object? value) {
    if (value is List || value is Map) return null;
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == '-') return null;
    return text;
  }

  String? _normalizeItemName(String? value) {
    if (value == null) return null;

    final parts = value.split('/').map((part) => part.trim()).toList();
    if (parts.length < 2) return value;

    final left = parts.first;
    final right = parts.last;
    final rightLooksLikeUnit = RegExp(r'\d|kg|g|개|마리|포기').hasMatch(right);
    return rightLooksLikeUnit ? left : right;
  }

  int? _priceValue(Object? value) {
    final text = _stringValue(value)?.replaceAll(',', '');
    if (text == null) return null;
    return int.tryParse(text);
  }

  double? _doubleValue(Object? value) {
    final text = _stringValue(value)?.replaceAll('%', '');
    if (text == null) return null;
    return double.tryParse(text);
  }

  String _formatPrice(int price) {
    final text = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i += 1) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}
