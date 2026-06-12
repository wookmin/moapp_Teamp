import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teamproject/repositories/app_repositories.dart';
import 'package:teamproject/screens/login/login_screen.dart';
import 'package:teamproject/theme/app_theme.dart';
import 'package:teamproject/widgets/app_shell.dart';
import 'package:teamproject/widgets/common_app_bar.dart';

void main() {
  setUp(() {
    AppRepositories.configure(firebaseEnabled: false);
  });

  testWidgets('main shell renders and switches tabs at 390x844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AppShell()),
    );
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('냉장고'), findsWidgets);
    expect(find.text('커뮤니티'), findsWidgets);
    expect(find.text('쇼핑'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('냉장고').last);
    await tester.pumpAndSettle();
    expect(find.text('내 냉장고'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('친구 냉장고'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('초대 코드 입력'));
    await tester.pumpAndSettle();
    expect(find.text('초대 코드 입력'), findsNWidgets(2));

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('친구에게 받은 8자리 코드를 입력하세요.'), findsNothing);
    expect(tester.takeException(), isNull);

    AppShell.selectTab(tester.element(find.text('내 냉장고')), 3);
    await tester.pumpAndSettle();
    expect(find.text('이번 장보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login remains usable at 360x800 with 130% text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: const LoginScreen(firebaseAvailable: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('먹을 건 놓치지 않고,\n살 건 정확하게'), findsOneWidget);
    expect(find.textContaining('웹 미리보기에서는'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('common app bar opens notifications by default', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(appBar: CommonAppBar()),
      ),
    );

    await tester.tap(find.byTooltip('알림'));
    await tester.pumpAndSettle();

    expect(find.text('알림'), findsOneWidget);
    expect(find.text('새로운 알림이 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
