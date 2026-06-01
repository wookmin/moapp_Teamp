import { createHash } from 'node:crypto';
import { resolve } from 'node:path';
import admin from 'firebase-admin';
import { readFileSync } from 'node:fs';

const PROJECT_DIR = '/Users/im_inwook/dev/MobileAppDevelopment/workspace/teamproject';
const SA_PATH = resolve(PROJECT_DIR, 'jangbogo-484bc-firebase-adminsdk-fbsvc-f615d5dfe3.json');
const serviceAccount = JSON.parse(readFileSync(SA_PATH, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'jangbogo-484bc',
});

const db = admin.firestore();
const ts = admin.firestore.FieldValue.serverTimestamp();

function hash(value: unknown): string {
  const body = typeof value === 'string' ? value : JSON.stringify(value);
  return createHash('sha256').update(body ?? '').digest('hex');
}

function stableId(value: string): string {
  return value.replace(/\s/g, '').toLowerCase();
}

function normalizeKeyword(value: string): string {
  return value.replace(/\s/g, '').trim().toLowerCase();
}

const SOURCE_LG = 'https://www.lge.co.kr/support/solutions-20150310896180';

interface FoodItem {
  nameKo: string;
  aliases?: string[];
  category?: string;
  state?: string;
  storageType: '실온' | '냉장' | '냉동' | '기타';
  temperature?: string;
  periodMinDays?: number;
  periodMaxDays?: number;
  periodText?: string;
  storageMethod?: string;
  cautions?: string[];
  sourceSentence: string;
  sourceUrl: string;
}

const foods: FoodItem[] = [
  { nameKo: '육류', aliases: ['고기', '정육'], category: '육류', storageType: '냉동', storageMethod: '밀봉 후 냉동보관. 대량구매 시 1회 조리단위로 나눠서 밀봉 후 냉동보관.', cautions: ['썰어진 제품은 산소와 닿는 면적이 넓어 부패가 쉬움', '상온에서 세균이 증식하므로 장볼 때 가장 마지막에 구매'], sourceSentence: '육류 – 밀봉 후 냉동보관', sourceUrl: SOURCE_LG },
  { nameKo: '어류', aliases: ['생선', '수산물'], category: '수산물', storageType: '냉장', storageMethod: '손질 후 위생팩 보관. 내장을 제거한 후 흐르는 찬물에 세척. 소금물에 담근 후 물기를 제거.', sourceSentence: '어류 – 손질 후 위생팩 보관', sourceUrl: SOURCE_LG },
  { nameKo: '우유', aliases: ['牛乳'], category: '유제품', state: '개봉 후', storageType: '냉장', periodMaxDays: 5, periodText: '개봉 후 5일 이내 섭취 권장', storageMethod: '다른 식품들과 떨어진 곳에 보관', cautions: ['냄새를 흡수하는 성질이 있어 다른 식품들과 떨어진 곳에 보관'], sourceSentence: '우유는 개봉 후 5일 이내 섭취 권장', sourceUrl: SOURCE_LG },
  { nameKo: '버터', category: '유제품', state: '개봉 후', storageType: '냉장', periodMaxDays: 30, periodText: '개봉 후 한달 이내 섭취 권장', sourceSentence: '버터는 한달 이내 섭취 권장', sourceUrl: SOURCE_LG },
  { nameKo: '두부', aliases: ['찌개두부', '부침두부', '순두부'], category: '가공식품', state: '개봉 후', storageType: '냉장', temperature: '5℃ 이하', storageMethod: '밀폐용기에 넣고 찬물을 부어 냉장고(5℃ 이하)에 보관. 가급적 빨리 섭취.', cautions: ['냉동하면 얼음결정이 생겨 질기고 탄력이 없어짐'], sourceSentence: '두부는 밀폐용기에 넣고 찬물을 부어 냉장(5℃ 이하) 보관', sourceUrl: SOURCE_LG },
  { nameKo: '견과류', aliases: ['호두', '아몬드', '땅콩', '잣', '캐슈넛'], category: '견과류', storageType: '냉장', storageMethod: '밀봉하여 빛이 통하지 않는 서늘한 곳(냉장고)에 보관. 장기 보관 시 냉동보관.', cautions: ['불포화 지방산이 많아 밀봉되지 않은 채 실온 보관 시 지방산패 및 곰팡이 발생', '껍질 깐 상태에서 곰팡이 번식이 활발'], sourceSentence: '밀봉시켜 서늘한 곳(냉장고)에 보관. 장기 보관 시 냉동보관.', sourceUrl: SOURCE_LG },
  { nameKo: '마요네즈', category: '조미료', storageType: '실온', storageMethod: '직사광선 피하고 서늘한 곳 보관', cautions: ['유화상태가 유지되지 않으면 쉽게 변질'], sourceSentence: '직사광선 피하고 서늘한 곳 보관', sourceUrl: SOURCE_LG },
  { nameKo: '빵', aliases: ['식빵', '베이커리'], category: '곡류/제과', storageType: '냉동', storageMethod: '장기간 보관 시 냉동보관. 단기간 보관 시 실온 또는 냉장보관.', cautions: ['실온 보관 시 곰팡이 쉽게 생김', '냉장 보관 시 수분 증발로 쉽게 말라버림'], sourceSentence: '장기간 보관 시 냉동보관. 단기간 보관 시 실온·냉장보관.', sourceUrl: SOURCE_LG },
  { nameKo: '사과', category: '과일', storageType: '냉장', temperature: '0~2℃', storageMethod: '개별 밀봉 후 4℃ 내외로 냉장보관', sourceSentence: '사과: 개별 밀봉 후 4℃ 내외로 냉장보관', sourceUrl: SOURCE_LG },
  { nameKo: '수박', category: '과일', state: '자른 후', storageType: '냉장', storageMethod: '지퍼백이나 비닐팩을 활용하여 냉장보관', sourceSentence: '자른 수박을 지퍼백이나 비닐팩으로 냉장보관', sourceUrl: SOURCE_LG },
  { nameKo: '포도', category: '과일', storageType: '냉장', temperature: '0~2℃', storageMethod: '종이에 싼 상태로 냉장보관', sourceSentence: '포도: 종이에 싼 상태로 냉장보관', sourceUrl: SOURCE_LG },
  { nameKo: '메론', aliases: ['멜론'], category: '과일', storageType: '실온', temperature: '10~15℃', storageMethod: '통풍이 잘 되는 곳에서 3~4일 보관 후 랩 싸서 냉장보관', sourceSentence: '메론: 통풍이 잘 되는 곳에서 3~4일 보관 후 냉장보관', sourceUrl: SOURCE_LG },
  { nameKo: '바나나', category: '과일', storageType: '실온', temperature: '13~16℃', storageMethod: '신문지로 싼 후 지퍼백에 개별 포장.', cautions: ['10℃ 이하 냉장 보관 시 껍질이 검게 변함'], sourceSentence: '바나나: 13~16℃ 실온 보관. 냉장 보관 시 껍질이 검게 변함.', sourceUrl: SOURCE_LG },
  { nameKo: '귤', aliases: ['오렌지', '감귤'], category: '과일', storageType: '실온', storageMethod: '통풍이 잘 되는 바구니에 신문지로 덮어서 보관', sourceSentence: '귤: 통풍이 잘 되는 바구니에 신문지로 덮어서 보관', sourceUrl: SOURCE_LG },
  { nameKo: '파인애플', category: '과일', storageType: '실온', temperature: '10~15℃', cautions: ['저온에서 상하기 쉬워 장기간 보관하지 말 것'], sourceSentence: '[10~15℃] 바나나, 파인애플, 자몽, 멜론, 레몬, 생강, 수박 등', sourceUrl: SOURCE_LG },
  { nameKo: '시금치', category: '채소', storageType: '냉장', storageMethod: '물 묻힌 종이에 싸서 보관. 장기간 보관 시 데친 다음 냉동보관.', sourceSentence: '시금치: 물 묻힌 종이에 싸서 보관. 장기간 보관 시 데친 다음 냉동보관.', sourceUrl: SOURCE_LG },
  { nameKo: '무', category: '채소', storageType: '냉장', storageMethod: '잎을 떼어낸 후 세워서 보관', sourceSentence: '무: 잎을 떼어낸 후 세워서 보관', sourceUrl: SOURCE_LG },
  { nameKo: '양파', category: '채소', storageType: '실온', storageMethod: '그물에 넣은 후 외부에 걸어서 보관', cautions: ['냉장고에 보관하면 오히려 보존 기간이 짧아짐'], sourceSentence: '양파: 그물에 넣은 후 외부에 걸어서 보관', sourceUrl: SOURCE_LG },
  { nameKo: '당근', category: '채소', storageType: '냉장', temperature: '0~2℃', storageMethod: '종이에 싸서 통풍이 잘 되고 서늘한 곳에 세워서 보관', sourceSentence: '당근: 종이에 싸서 통풍이 잘 되는 서늘한 곳에 보관', sourceUrl: SOURCE_LG },
  { nameKo: '대파', aliases: ['파'], category: '채소', storageType: '냉장', storageMethod: '녹색부분은 종이에 싸서, 흰색부분은 비닐봉지에 넣어서 냉장보관', sourceSentence: '파: 녹색부분은 종이에 싸서, 흰색부분은 비닐봉지에 넣어서 냉장보관', sourceUrl: SOURCE_LG },
  { nameKo: '오이', category: '채소', storageType: '냉장', temperature: '4~10℃', storageMethod: '종이에 싸서 냉장보관. 장기 보관 시 소금으로 절여 물기제거 후 냉동보관.', sourceSentence: '오이: 종이에 싸서 냉장보관', sourceUrl: SOURCE_LG },
  { nameKo: '고구마', category: '채소', storageType: '실온', storageMethod: '밀폐용기에 넣어 실온 보관', cautions: ['냉장고에 보관하면 오히려 보존 기간이 짧아짐'], sourceSentence: '고구마 등은 냉장고에 보관하면 보존 기간이 짧아짐', sourceUrl: SOURCE_LG },
  { nameKo: '마늘', category: '채소', storageType: '실온', storageMethod: '밀폐용기에 넣어 실온 보관', cautions: ['냉장고에 보관하면 오히려 보존 기간이 짧아짐'], sourceSentence: '마늘 등은 냉장고에 보관하면 보존 기간이 짧아짐', sourceUrl: SOURCE_LG },
  { nameKo: '고추', aliases: ['청양고추', '홍고추'], category: '채소', storageType: '실온', storageMethod: '밀폐용기에 넣어 실온 보관', cautions: ['냉장고에 보관하면 오히려 보존 기간이 짧아짐'], sourceSentence: '고추 등은 냉장고에 보관하면 보존 기간이 짧아짐', sourceUrl: SOURCE_LG },
];

async function main() {
  let count = 0;
  for (const food of foods) {
    const ingredientId = stableId(food.nameKo);
    const ingredientRef = db.collection('ingredients').doc(ingredientId);
    const batch = db.batch();

    batch.set(ingredientRef, {
      nameKo: food.nameKo,
      nameEn: null,
      category: food.category ?? null,
      description: null,
      aliases: food.aliases ?? [],
      searchKeywords: [
        normalizeKeyword(food.nameKo),
        ...(food.aliases ?? []).map(normalizeKeyword),
      ],
      createdAt: ts,
      updatedAt: ts,
    }, { merge: true });

    const ruleId = hash({ nameKo: food.nameKo, state: food.state, storageType: food.storageType, storageMethod: food.storageMethod }).slice(0, 24);
    batch.set(ingredientRef.collection('storage_rules').doc(ruleId), {
      state: food.state ?? null,
      storageType: food.storageType,
      temperature: food.temperature ?? null,
      periodMinDays: food.periodMinDays ?? null,
      periodMaxDays: food.periodMaxDays ?? null,
      periodText: food.periodText ?? null,
      storageMethod: food.storageMethod ?? null,
      caution: (food.cautions ?? []).join('\n') || null,
      confidence: 0.95,
      reviewStatus: 'auto_approved',
      createdAt: ts,
      updatedAt: ts,
    }, { merge: true });

    const sourceId = hash({ sourceUrl: food.sourceUrl, sourceSentence: food.sourceSentence }).slice(0, 24);
    batch.set(ingredientRef.collection('sources').doc(sourceId), {
      sourceName: 'LG전자 냉장고 식품별 보관 방법',
      sourceUrl: food.sourceUrl,
      sourceType: 'official',
      sourceSentence: food.sourceSentence,
      verifiedAt: ts,
      documentHash: sourceId,
    }, { merge: true });

    for (const keyword of [food.nameKo, ...(food.aliases ?? [])]) {
      const nk = normalizeKeyword(keyword);
      if (!nk) continue;
      batch.set(db.collection('ingredient_search_index').doc(nk), {
        keyword,
        normalizedKeyword: nk,
        ingredientId,
        nameKo: food.nameKo,
        type: keyword === food.nameKo ? 'name' : 'alias',
      }, { merge: true });
    }

    await batch.commit();
    console.log(`✓ ${food.nameKo} (${ingredientId})`);
    count++;
  }

  // 검증
  const check = await db.collection('ingredient_search_index').doc('견과류').get();
  console.log('\n검증 - ingredient_search_index/견과류:', check.exists ? check.data() : '❌ 없음');
  console.log(`\n완료: ${count}개 저장`);
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
