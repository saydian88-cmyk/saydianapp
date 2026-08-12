import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/feature_models.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/api_client.dart';
import 'package:saydian_app/services/app_controller.dart';
import 'package:saydian_app/services/local_health_store.dart';
import 'package:saydian_app/services/secure_vault.dart';
import 'package:saydian_app/services/wearable_bridge.dart';
import 'package:saydian_app/ui/pages.dart';
import 'package:saydian_app/ui/prototype_pages.dart';

void main() {
  test('feature availability always has plain user copy', () {
    expect(
      const FeatureAvailability(FeatureAvailabilityStatus.needsDevice).message,
      '连接手表后使用',
    );
    expect(
      const FeatureAvailability(
        FeatureAvailabilityStatus.needsPermission,
      ).message,
      '允许相关权限后使用',
    );
    expect(
      const FeatureAvailability(
        FeatureAvailabilityStatus.unsupportedDevice,
      ).message,
      '当前手表不支持此功能',
    );
    expect(
      const FeatureAvailability(
        FeatureAvailabilityStatus.serviceUnavailable,
      ).message,
      '此功能暂时无法使用，请稍后再试',
    );
  });

  test('device capabilities map health and device features independently', () {
    final capabilities = DeviceCapabilities.fromMap(const {
      'metrics': ['heart_rate', 'blood_glucose'],
      'features': ['find_watch', 'screen_display', 'contacts'],
      'integratedFeatures': ['find_watch', 'screen_display'],
    });
    expect(capabilities.supports(HealthMetric.heartRate), isTrue);
    expect(capabilities.supports(HealthMetric.bloodGlucose), isTrue);
    expect(capabilities.supportsFeature(DeviceFeature.contacts), isTrue);
    expect(
      capabilities.integratedFeatures,
      containsAll([DeviceFeature.findWatch, DeviceFeature.screenDisplay]),
    );
  });

  testWidgets(
    'device page exposes the full settings catalogue with safe state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DevicePage(controller: controller)),
        ),
      );

      expect(find.text('添加智能设备'), findsOneWidget);
      expect(find.text('表盘中心'), findsOneWidget);
      await tester.ensureVisible(find.text('屏幕显示'));
      await tester.pumpAndSettle();
      expect(find.text('查找手表'), findsOneWidget);
      expect(find.text('常用联系人'), findsOneWidget);
      expect(find.text('健康提醒'), findsOneWidget);
      expect(find.text('屏幕显示'), findsOneWidget);

      await tester.tap(find.text('屏幕显示'));
      await tester.pumpAndSettle();
      expect(find.text('连接手表后使用'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('connected device feature pages render real controls', (
    tester,
  ) async {
    final wearable = _FeatureWearable();
    final controller = AppController(
      MemorySessionVault(),
      _CoverageApi(),
      MemoryHealthStore(),
      wearable,
    )..isBooting = false;
    addTearDown(controller.dispose);
    await controller.connectDevice(
      const DeviceInfo(id: 'WATCH:01', name: 'Test Watch', model: 'JL'),
    );

    final cases = <DeviceFeature, String>{
      DeviceFeature.watchFaces: '系统表盘 1',
      DeviceFeature.photoWatchFace: '选择一张照片制作表盘',
      DeviceFeature.notifications: '还需允许手机通知权限',
      DeviceFeature.alarms: '添加闹钟',
      DeviceFeature.contacts: '添加联系人',
      DeviceFeature.weather: '更新当前位置天气',
      DeviceFeature.worldClock: '添加城市',
      DeviceFeature.healthReminders: '久坐提醒',
      DeviceFeature.healthAssessment: '压力评估',
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: DeviceFeaturePage(
            controller: controller,
            feature: entry.key,
            key: ValueKey(entry.key),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key.name);
    }
  });

  testWidgets('password recovery validates input without claiming success', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PasswordRecoveryPage()));
    await tester.enterText(
      find.byKey(const Key('password-recovery-mobile')),
      '123',
    );
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pump();
    expect(find.text('请输入正确的中国大陆手机号'), findsOneWidget);
  });

  test('release UI source does not contain developer-facing copy', () {
    final source = [
      'lib/app.dart',
      'lib/ui/pages.dart',
      'lib/ui/shop_pages.dart',
      'lib/ui/prototype_pages.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');
    for (final banned in [
      'Veepoo',
      'SDK',
      'BLE',
      '接口未配置',
      '错误码',
      '指令队列',
      '本地预览',
      '内测版',
      '真机验证',
      'openid',
    ]) {
      expect(source, isNot(contains(banned)), reason: 'UI contains $banned');
    }
  });
}

AppController _controller() => AppController(
  MemorySessionVault(),
  _CoverageApi(),
  MemoryHealthStore(),
  _CoverageWearable(),
)..isBooting = false;

class _CoverageApi extends Fake implements SaydianApi {}

class _CoverageWearable extends Fake implements WearableBridge {
  @override
  Stream<WearableEvent> get events => const Stream.empty();
}

class _FeatureWearable extends Fake implements WearableBridge {
  @override
  Stream<WearableEvent> get events => const Stream.empty();

  @override
  Future<void> connect(
    String deviceId, {
    required WearableUserProfile profile,
  }) async {}

  @override
  Future<DeviceCapabilities> getCapabilities() async => DeviceCapabilities(
    metrics: const {HealthMetric.heartRate},
    features: DeviceFeature.values.toSet(),
    integratedFeatures: DeviceFeature.values.toSet(),
  );

  @override
  Future<List<HealthRecord>> syncHealthData({String? cursor}) async => const [];

  @override
  Future<List<SportRecord>> readSportRecords() async => const [];

  @override
  Future<Map<String, Object?>> readDeviceFeature(DeviceFeature feature) async =>
      switch (feature) {
        DeviceFeature.watchFaces => {
          'items': [
            {
              'id': '/system/1',
              'name': '系统表盘 1',
              'type': 'system',
              'index': 0,
              'isCurrent': true,
            },
          ],
        },
        DeviceFeature.photoWatchFace => const {},
        DeviceFeature.notifications => {
          'notificationAccess': false,
          'supportedKeys': ['wechat', 'sms'],
          'wechat': true,
          'sms': true,
        },
        DeviceFeature.alarms => {'items': <Object?>[]},
        DeviceFeature.contacts => {'items': <Object?>[]},
        DeviceFeature.weather => {'enabled': true, 'useCelsius': true},
        DeviceFeature.worldClock => {'items': <Object?>[]},
        DeviceFeature.healthReminders => {
          'items': [
            {
              'id': 'sedentary',
              'label': '久坐提醒',
              'enabled': true,
              'startMinutes': 480,
              'endMinutes': 1320,
              'intervalMinutes': 60,
            },
          ],
        },
        DeviceFeature.healthAssessment => {
          'items': [
            {'id': 6, 'label': '压力评估', 'enabled': true},
          ],
        },
        _ => const {},
      };

  @override
  Future<void> writeDeviceFeature(
    DeviceFeature feature,
    Map<String, Object?> values,
  ) async {}

  @override
  Future<void> triggerDeviceAction(
    DeviceFeature feature, {
    bool enabled = true,
  }) async {}
}
