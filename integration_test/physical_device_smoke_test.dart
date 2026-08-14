import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saydian_app/app.dart';
import 'package:saydian_app/domain/feature_models.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/app_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('physical device health and ET488 smoke test', (tester) async {
    final controller = AppController.production();
    addTearDown(controller.dispose);
    await controller.initialize();
    if (!controller.isAuthenticated) controller.enterPreview();

    await tester.pumpWidget(SaydianApp(controller: controller));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('健康数据'), findsOneWidget);
    for (final title in const [
      '血压',
      '血糖',
      '血氧',
      '体温',
      '心电',
      '心率',
      'HRV',
      '身体成分',
      '睡眠',
      '血液成分',
    ]) {
      expect(find.text(title), findsWidgets, reason: '$title 首页入口缺失');
    }

    final heartRateCard = find.byKey(const ValueKey('health-metric-heartRate'));
    await tester.ensureVisible(heartRateCard);
    await tester.pumpAndSettle();
    await tester.tap(heartRateCard);
    await tester.pumpAndSettle();
    expect(find.text('心率分析'), findsOneWidget);
    await tester.tap(find.text('周'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    controller.selectTab(3);
    await tester.pumpAndSettle();
    if (controller.connectedDevice == null) {
      await controller.scanDevices();
      await _waitUntil(
        tester,
        () => controller.scannedDevices.any(
          (device) => device.name.toUpperCase().contains('ET488'),
        ),
        const Duration(seconds: 18),
      );
      final et488 = controller.scannedDevices.firstWhere(
        (device) => device.name.toUpperCase().contains('ET488'),
      );
      await controller.connectDevice(et488);
    }
    await _waitUntil(
      tester,
      () => controller.connectedDevice != null,
      const Duration(seconds: 25),
    );
    expect(controller.connectedDevice?.name.toUpperCase(), contains('ET488'));
    expect(controller.connectedDevice?.sdkSource, WearableSdkSource.veepoo);
    await tester.pumpAndSettle();
    expect(find.text('ET'), findsWidgets);

    await controller.readDeviceFeature(DeviceFeature.watchFaces);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('表盘中心'));
    await tester.tap(find.text('表盘中心'));
    await _waitUntil(
      tester,
      () => find.text('示意').evaluate().isNotEmpty,
      const Duration(seconds: 20),
    );
    expect(find.text('示意'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await controller.syncDeviceData();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(controller.connectedDevice, isNotNull);
    expect(controller.deviceState, isNot(DeviceConnectionState.disconnected));
    final capabilities = controller.capabilities;
    expect(capabilities, isNotNull);
    debugPrint(
      'ET488_CAPABILITIES:${capabilities!.metrics.map((metric) => metric.wireName).join(',')}',
    );

    const manuallyMeasured = [
      // ECG requires the watch to be idle, so exercise it before the shorter
      // optical measurements and leave a settling gap after every stop.
      HealthMetric.ecg,
      HealthMetric.heartRate,
      HealthMetric.bloodOxygen,
      HealthMetric.bloodPressure,
      HealthMetric.bodyTemperature,
      HealthMetric.bloodGlucose,
      HealthMetric.bodyComposition,
      HealthMetric.bloodComposition,
    ];
    for (final metric in manuallyMeasured.where(capabilities.supports)) {
      controller.clearError();
      await controller.startMeasurement(metric);
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        controller.errorMessage,
        isNull,
        reason: '${metric.label}真机测量启动失败',
      );
      await controller.stopMeasurement(metric);
      await tester.pump(const Duration(seconds: 1));
      expect(
        controller.errorMessage,
        isNull,
        reason: '${metric.label}真机测量停止失败',
      );
      debugPrint('ET488_MEASUREMENT_OK:${metric.wireName}');
    }

    final connectedId = controller.connectedDevice!.id;
    await controller.disconnectDevice();
    expect(controller.connectedDevice, isNull);
    final rediscovered = await _scanForDevice(
      tester,
      controller,
      (device) => device.id == connectedId,
    );
    await controller.connectDevice(rediscovered);
    await _waitUntil(
      tester,
      () => controller.connectedDevice?.id == connectedId,
      const Duration(seconds: 25),
    );
    expect(controller.deviceState, isNot(DeviceConnectionState.disconnected));
    debugPrint('ET488_RECONNECT_OK:$connectedId');

    controller.selectTab(1);
    await tester.pumpAndSettle();
    for (final sport in const ['跑步', '步行', '骑行']) {
      expect(find.text(sport), findsWidgets);
    }

    controller.selectTab(4);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('联系客服'));
    await tester.tap(find.text('联系客服'));
    await tester.pumpAndSettle();
    expect(find.text('4006386738'), findsOneWidget);
    expect(find.text('公众号'), findsOneWidget);
    expect(find.text('添加客服'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('关于我们'));
    await tester.tap(find.text('关于我们'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('在线更新服务暂未配置'), findsOneWidget);
  });
}

Future<DeviceInfo> _scanForDevice(
  WidgetTester tester,
  AppController controller,
  bool Function(DeviceInfo device) matches,
) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    await controller.scanDevices();
    final matchesNow = controller.scannedDevices.where(matches);
    if (matchesNow.isNotEmpty) return matchesNow.first;
    await tester.pump(const Duration(seconds: 3));
  }
  fail('三轮搜索后仍未重新发现目标手表');
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition,
  Duration timeout,
) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(condition(), isTrue);
}
