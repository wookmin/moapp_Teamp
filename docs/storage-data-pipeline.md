# Storage Data Pipeline

본 서비스는 AI가 보관 정보를 임의 생성하지 않고, 국내 공식 API 및 공식 자료에서 추출한 정보를 구조화하여 Firebase에 저장한 뒤 제공합니다. 출처 문장과 URL이 없는 정보는 자동 승인하지 않습니다.

## 목적

사용자가 식재료나 식품명을 검색하면 보관 위치, 보관 기간, 보관 방법, 주의사항, 상한 상태 판단 기준을 공식 근거 기반으로 보여준다. 해외 API, 개인 블로그, 카페 글, 출처 불명 자료는 사용하지 않는다.

## 데이터 소스

- 식품안전나라 OpenAPI
- 식약처, 식품안전나라 등 국내 공식 기관의 PDF/HTML 자료

공식 도메인이 아닌 URL은 자동 승인하지 않고 검수 대상으로 둔다.

## Firestore 구조

- `raw_documents`: API/PDF/HTML 원본 저장
- `extracted_storage_candidates`: AI가 원문에서 추출한 후보 저장
- `review_queue`: 검수 필요 후보 저장
- `ingredients`: 서비스 검색용 식재료 마스터
- `ingredients/{ingredientId}/storage_rules`: 승인된 보관 규칙
- `ingredients/{ingredientId}/spoilage_signs`: 상한 상태 판단 기준
- `ingredients/{ingredientId}/usage_tips`: 활용 팁
- `ingredients/{ingredientId}/sources`: 공식 출처와 근거 문장
- `ingredient_search_index`: 검색어 정규화 인덱스

## 환경변수

`.env` 또는 쉘 환경변수로 설정한다.

```bash
FOODSAFETY_API_KEY=
FOODSAFETY_STORAGE_API_URL=https://www.foodsafetykorea.go.kr/portalmobile/content/detail.do?bbs_no=bbs427&ntctxt_no=1069310
GEMINI_API_KEY=
FIREBASE_PROJECT_ID=
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

`FOODSAFETY_STORAGE_API_URL`을 지정하지 않으면 식품안전나라의 공식 보관/저장 HTML 문서를 기본 수집 대상으로 사용한다. 실제 OpenAPI URL을 넣은 경우 API 키가 없으면 수집 단계는 실패하지 않고 disabled 로그를 남긴다. `GEMINI_API_KEY`가 없으면 AI 추출은 skipped 처리된다.

## 실행 명령어

```bash
npm run storage:collect:foodsafety
npm run storage:collect:sources
npm run storage:extract
npm run storage:extract:retry
npm run storage:import
npm run storage:review:list
npm run storage:review:approve -- --id REVIEW_ID
npm run storage:review:reject -- --id REVIEW_ID
npm run storage:seed:mock
```

## AI 역할

AI는 공식 원문에서 JSON 필드를 추출하는 역할만 한다.

- 공식 자료/API 응답에 있는 내용만 추출
- 자료에 없는 내용은 추측 금지
- 불확실하면 `null`
- `source_sentence` 필수
- JSON 이외의 설명 금지

1차 추출은 `gemini-2.5-flash-lite`, 재시도는 `gemini-2.5-flash`를 사용한다.

## 자동 승인 정책

다음 조건을 모두 만족해야 `auto_approved`가 된다.

- `sourceSentence` 있음
- `sourceUrl` 있음
- 국내 공식 기관 도메인
- `storageType` 있음
- `confidence >= 0.8`
- 기간/온도 오류 없음

검증 실패 후보는 `pending_review` 또는 `rejected`로 저장된다. Flutter 검색 화면은 `auto_approved` 데이터만 읽는다.

## 검수 흐름

```bash
npm run storage:review:list
npm run storage:review:approve -- --id REVIEW_ID
npm run storage:review:reject -- --id REVIEW_ID
```

approve 시 후보가 `ingredients` 및 하위 컬렉션으로 반영되고 `ingredient_search_index`가 생성된다. reject 시 후보와 검수 큐가 rejected 상태로 바뀐다.

## Flutter 검색 연결

검색 화면은 `FirebaseStorageSearchRepository`를 통해 아래 흐름으로 데이터를 읽는다.

1. 검색어 정규화
2. `ingredient_search_index/{normalizedKeyword}` 조회
3. `ingredients/{ingredientId}` 조회
4. `storage_rules` 중 `reviewStatus == auto_approved`만 조회
5. `StorageTip` 카드 모델로 변환

검색 시 AI가 즉석에서 보관법을 생성하지 않는다.
