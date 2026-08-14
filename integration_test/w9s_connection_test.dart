import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/app_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('W9S connects and completes a health sync on iOS', (
    tester,
  ) async {
    final controller = AppController.production();
    await controller.initialize();
    if (!controller.isAuthenticated) controller.enterPreview();
    addTearDown(() async {
      if (controller.connectedDevice != null) {
        await controller.disconnectDevice();
      }
      controller.dispose();
    });

    // Give the watch time to resume advertising after the normal app is
    // replaced by the integration-test runner.
    await tester.pump(const Duration(seconds: 2));
    final w9s = await _findW9s(tester, controller);
    expect(w9s.sdkSource, WearableSdkSource.veepoo);
    debugPrint('W9S_DISCOVERED:${w9s.id}:${w9s.name}:${w9s.rssi}');

    await controller.connectDevice(w9s);
    await _waitUntil(
      tester,
      () => controller.connectedDevice?.id == w9s.id,
      const Duration(seconds: 35),
    );
    expect(controller.deviceState, DeviceConnectionState.ready);
    expect(controller.capabilities, isNotNull);
    debugPrint(
      'W9S_CONNECTED:${controller.connectedDevice?.firmwareVersion ?? ''}:'
      '${controller.capabilities!.metrics.map((metric) => metric.wireName).join(',')}',
    );

    await _waitUntil(
      tester,
      () => !controller.isDeviceSyncing,
      const Duration(seconds: 45),
    );
    controller.clearError();
    await controller.syncDeviceData();
    await _waitUntil(
      tester,
      () => !controller.isDeviceSyncing,
      const Duration(seconds: 45),
    );
    debugPrint(
      'W9S_SYNC:${controller.syncStatus}:'
      '${controller.errorMessage ?? 'OK'}:'
      '${controller.healthRecords.length}',
    );
    expect(controller.connectedDevice?.id, w9s.id);
    expect(controller.deviceState, DeviceConnectionState.ready);
    expect(controller.errorMessage, isNull);
    expect(controller.syncStatus, anyOf(startsWith('已同步 '), equals('设备暂无新数据')));
  });
}

Future<DeviceInfo> _findW9s(
  WidgetTester tester,
  AppController controller,
) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    await controller.scanDevices();
    final matches = controller.scannedDevices.where((device) {
      final normalized = device.name.toUpperCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      return normalized.contains('W9S') || normalized.contains('W9');
    });
    if (matches.isNotEmpty) return matches.first;
    await tester.pump(const Duration(seconds: 3));
  }
  fail('三轮扫描后仍未发现 W9/W9S');
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
