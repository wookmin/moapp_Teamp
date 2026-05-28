import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teamproject/main.dart';

void main() {
  testWidgets('login screen opens and navigates to profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TeamProjectApp());

    expect(find.text('냉장고 관리를\n다시 이어가세요'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);

    await tester.tap(find.text('로그인'));
    await tester.pumpAndSettle();

    expect(find.text('신선도 게이지'), findsOneWidget);

    await tester.tap(find.text('마이페이지'));
    await tester.pumpAndSettle();

    expect(find.text('Elena Greenwell'), findsOneWidget);
    expect(find.text('84%'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('냉장고 설정'),
      120,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('냉장고 설정'), findsOneWidget);
  });
}
