# KAMIS API Integration

장보기 추천과 AI 레시피 추천은 KAMIS 농수산물 가격 동향을 선택적으로 사용한다.

## Environment

앱 실행 시 `.env`에서 아래 값을 읽는다.

```bash
KAMIS_API_KEY=
KAMIS_API_ID=
```

둘 중 하나라도 없으면 KAMIS 연동은 비활성화되고, 앱은 빈 추천 상태를 보여준다.

## Current Usage

- `KamisPriceService`
  - KAMIS `dailySalesList` JSON API를 호출한다.
  - 최근 가격, 전일/전월/전년 가격, 등락 방향, 등락률을 `PriceTrend`로 변환한다.
- `KamisShoppingRecommendationRepository`
  - 가격 하락 품목을 `오늘 가격이 내려간 재료` 섹션으로 노출한다.
  - 가격 하락이 아닌 품목은 `가격 동향 확인 재료` 섹션으로 분리한다.
- `RecipeRecommendationService`
  - 레시피 후보 점수화와 Gemini 추천 프롬프트에 `PriceTrend`를 전달한다.

## Production Note

현재는 Flutter 앱에서 직접 KAMIS API를 호출한다. 배포용 앱에서는 API 인증 정보 노출을 막기 위해 Firebase Functions 또는 별도 서버를 경유하는 구조로 바꾸는 것을 권장한다.
