import '../../models/storage_tip.dart';
import '../storage_search_repository.dart';

class PlaceholderStorageSearchRepository implements StorageSearchRepository {
  const PlaceholderStorageSearchRepository();

  static const _tips = <StorageTip>[
    StorageTip(
      title: '우유',
      tag: '냉장',
      summary: '개봉 전에는 포장 표시일을 우선으로 보고, 개봉 후에는 가능한 빨리 마시는 것이 좋아요.',
      storageMethod: '냉장고 안쪽 0~5도 구역에 세워서 보관하세요. 문 쪽은 온도 변화가 커서 피하는 편이 좋아요.',
      expiryGuide: '개봉 후 3~5일 안에 섭취를 권장해요.',
      consumeTip: '남은 우유는 프렌치토스트, 크림파스타, 팬케이크 반죽에 활용하기 좋아요.',
      source: '기본 보관 팁',
    ),
    StorageTip(
      title: '두부',
      tag: '냉장',
      summary: '개봉한 두부는 물을 갈아주며 밀폐 보관하면 신선도를 조금 더 유지할 수 있어요.',
      storageMethod: '밀폐 용기에 두부가 잠길 정도의 깨끗한 물을 넣고 냉장 보관하세요.',
      expiryGuide: '개봉 후 2~3일 안에 먹는 것을 권장해요.',
      consumeTip: '찌개, 두부조림, 두부부침처럼 수분을 날리는 요리에 쓰면 좋아요.',
      source: '기본 보관 팁',
    ),
    StorageTip(
      title: '대파',
      tag: '냉장/냉동',
      summary: '바로 쓸 대파는 냉장, 오래 둘 대파는 손질 후 냉동하면 활용하기 편해요.',
      storageMethod: '물기를 제거한 뒤 키친타월로 감싸 밀폐 용기나 지퍼백에 보관하세요.',
      expiryGuide: '냉장은 약 7일, 냉동은 약 1~2개월 안에 사용하는 것을 권장해요.',
      consumeTip: '송송 썰어 냉동해두면 국, 볶음밥, 라면에 바로 넣기 좋아요.',
      source: '기본 보관 팁',
    ),
    StorageTip(
      title: '계란',
      tag: '냉장',
      summary: '계란은 씻지 않은 상태로 뾰족한 부분이 아래로 가게 보관하는 것이 좋아요.',
      storageMethod: '냉장고 안쪽에 원래 포장 그대로 보관하세요. 냄새가 강한 식품과는 떨어뜨려 두세요.',
      expiryGuide: '구입 후 약 2~3주 안에 섭취를 권장해요.',
      consumeTip: '임박하면 삶은 계란, 계란말이, 볶음밥 재료로 빠르게 소진하기 좋아요.',
      source: '기본 보관 팁',
    ),
    StorageTip(
      title: '삼겹살',
      tag: '냉장/냉동',
      summary: '냉장 보관 기간이 짧아서 바로 먹지 않을 경우 소분 냉동이 안전해요.',
      storageMethod: '키친타월로 핏물을 제거하고 1회분씩 랩으로 감싸 밀폐해 보관하세요.',
      expiryGuide: '냉장은 1~3일, 냉동은 약 1개월 안에 사용하는 것을 권장해요.',
      consumeTip: '임박한 삼겹살은 구이, 김치볶음, 된장찌개용으로 빠르게 활용해보세요.',
      source: '기본 보관 팁',
    ),
    StorageTip(
      title: '버섯',
      tag: '냉장',
      summary: '버섯은 습기에 약해서 물기 제거와 통풍이 중요해요.',
      storageMethod: '씻지 말고 키친타월로 감싸 종이봉투나 밀폐 용기에 냉장 보관하세요.',
      expiryGuide: '구입 후 3~5일 안에 사용하는 것을 권장해요.',
      consumeTip: '숨이 죽기 시작하면 볶음, 전골, 크림수프에 넣어 소진하기 좋아요.',
      source: '기본 보관 팁',
    ),
  ];

  @override
  Future<List<StorageTip>> searchStorageTips(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return _tips.where((tip) {
      final target = [
        tip.title,
        tip.tag,
        tip.summary,
        tip.storageMethod,
        tip.expiryGuide,
        tip.consumeTip,
      ].whereType<String>().join(' ').toLowerCase();
      return target.contains(normalizedQuery);
    }).toList();
  }
}
