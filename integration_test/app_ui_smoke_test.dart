import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saydian_app/app.dart';
import 'package:saydian_app/services/app_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('physical phone UI compatibility smoke test', (tester) async {
    final controller = AppController.production();
    addTearDown(controller.dispose);
    await controller.initialize();
    if (!controller.isAuthenticated) controller.enterPreview();

    await tester.pumpWidget(SaydianApp(controller: controller));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('健康数据'), findsOneWidget);

    final heartRate = find.byKey(const ValueKey('health-metric-heartRate'));
    await tester.scrollUntilVisible(
      heartRate,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(heartRate);
    await tester.pumpAndSettle();
    expect(find.text('心率分析'), findsOneWidget);
    await tester.tap(find.text('周'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    controller.selectTab(4);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('联系客服'));
    await tester.tap(find.text('联系客服'));
    await tester.pumpAndSettle();
    expect(find.text('4006386738'), findsOneWidget);
    expect(find.text('添加客服'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('关于我们'));
    await tester.tap(find.text('关于我们'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);
  });
}
