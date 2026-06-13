import 'package:flutter_test/flutter_test.dart';
import 'package:teamproject/services/receipt_ocr_service.dart';

void main() {
  test('receipt OCR parser extracts numbered product lines', () {
    final service = ReceiptOcrService();
    const receiptText = '''
상품코드 단가 수량 금액
001 소단량가슴살300g
8608329610113 4,550 1 4,550
002 브로커리(2입/봉)
1500000053376 2,780 1 2,780
003 파프리카(3입/봉)
1500000018153 5,480 1 5,480
004 국산 볶음땅콩150g
8809205164010 4,820 1 4,820
005 적양배추1/2
1133640108001 10,800 1 10,800
006 양상추
1500000007025 1,280 1 1,280
합계 29,710
''';

    final items = service.parseReceiptText(receiptText);

    expect(items.map((item) => item.rawName), [
      '소단량가슴살300g',
      '브로커리(2입/봉)',
      '파프리카(3입/봉)',
      '국산 볶음땅콩150g',
      '적양배추1/2',
      '양상추',
    ]);
    expect(items.map((item) => item.name), [
      '닭가슴살',
      '브로콜리',
      '파프리카',
      '땅콩',
      '적양배추',
      '양상추',
    ]);
    expect(items.every((item) => item.isSelected), isTrue);
  });

  test('receipt recognition prefers the most specific food keyword', () {
    final service = ReceiptOcrService();

    final items = service.parseReceiptText('003파프리카(3입/봉)');

    expect(items.single.name, '파프리카');
  });

  test('receipt OCR parser ignores noise and recovers split product lines', () {
    final service = ReceiptOcrService();
    const visionText = '''
1 BC
소단량가슴살300g
002
브로커리(2입/봉)
003 파프리카(3입/봉)
국산 볶음땅콩150g
적양배추1/2
양상추
카드 결제 29,710
''';

    final items = service.parseReceiptText(visionText);

    expect(items.map((item) => item.name), [
      '파프리카',
      '닭가슴살',
      '브로콜리',
      '땅콩',
      '적양배추',
      '양상추',
    ]);
    expect(items.any((item) => item.rawName.contains('BC')), isFalse);
  });
}
