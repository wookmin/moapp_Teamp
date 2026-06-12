import 'package:flutter/material.dart';

IconData foodIconFor(String name, {String? category}) {
  final target = '${category ?? ''} $name'.toLowerCase();

  if (_containsAny(target, ['우유', '치즈', '요거트', '유제품'])) {
    return Icons.water_drop_outlined;
  }
  if (_containsAny(target, ['고기', '삼겹', '소고기', '돼지', '닭'])) {
    return Icons.restaurant_outlined;
  }
  if (_containsAny(target, ['생선', '고등어', '새우', '해산물'])) {
    return Icons.set_meal_outlined;
  }
  if (_containsAny(target, ['사과', '딸기', '바나나', '포도', '과일'])) {
    return Icons.circle_outlined;
  }
  if (_containsAny(target, ['빵', '밥', '쌀', '곡물'])) {
    return Icons.bakery_dining_outlined;
  }
  if (_containsAny(target, ['계란', '달걀'])) {
    return Icons.egg_outlined;
  }
  if (_containsAny(target, ['냉동'])) return Icons.ac_unit_rounded;
  return Icons.eco_outlined;
}

bool _containsAny(String value, List<String> candidates) {
  return candidates.any(value.contains);
}
