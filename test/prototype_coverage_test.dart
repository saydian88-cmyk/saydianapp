import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saydian_app/domain/feature_models.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/api_client.dart';
import 'package:saydian_app/services/app_controller.dart';
import 'package:saydian_app/services/local_health_store.dart';
import 'package:saydian_app/services/secure_vault.dart';
import 'package:saydian_app/services/wearable_bridge.dart';
import 'package:saydian_app/ui/pages.dart';
import 'package:saydian_app/ui/device_sdk_badge.dart';
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
      const DeviceInfo(id: 'veepoo:WATCH:01', name: 'Test Watch', model: 'JL'),
    );
    expect(controller.connectedDevice?.sdkSource, WearableSdkSource.veepoo);

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
      final badge = tester.widget<DeviceSdkBadge>(find.byType(DeviceSdkBadge));
      expect(badge.source, WearableSdkSource.veepoo, reason: entry.key.name);
      if (entry.key == DeviceFeature.watchFaces) {
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == '系统表盘 1预览暂不可用',
          ),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('feature page defers device reads until after its first frame', (
    tester,
  ) async {
    final controller = AppController(
      MemorySessionVault(),
      _CoverageApi(),
      MemoryHealthStore(),
      _FeatureWearable(),
    )..isBooting = false;
    addTearDown(controller.dispose);
    await controller.connectDevice(
      const DeviceInfo(id: 'yucheng:WATCH:01', name: 'Test Watch', model: 'JL'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ListenableBuilder(
          listenable: controller,
          builder: (_, _) => DeviceFeaturePage(
            controller: controller,
            feature: DeviceFeature.screenDisplay,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('password recovery validates input without claiming success', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: PasswordRecoveryPage(controller: controller)),
    );
    await tester.enterText(
      find.byKey(const Key('password-recovery-mobile')),
      '123',
    );
    await tester.tap(find.byKey(const Key('password-recovery-submit')));
    await tester.pump();
    expect(find.text('请输入正确的中国大陆手机号'), findsOneWidget);
  });

  testWidgets('about, contact and feedback pages follow the prototype flow', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AboutSaydianPage(
          controller: controller,
          packageInfoLoader: () async => PackageInfo(
            appName: '赛电健康',
            packageName: 'com.saydian.app',
            version: '0.1.12',
            buildNumber: '14',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('V0.1.12 (14)'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('在线更新服务暂未配置'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: CustomerServicePage()));
    await tester.pumpAndSettle();
    expect(find.text('4006386738'), findsOneWidget);
    expect(find.text('公众号'), findsOneWidget);
    expect(find.text('赛电'), findsOneWidget);
    expect(find.text('添加客服'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: FeedbackPage()));
    await tester.pumpAndSettle();
    expect(find.text('问题反馈'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('常见问题'), findsOneWidget);
  });

  test('release UI source does not contain developer-facing copy', () {
    final source = [
      'lib/app.dart',
      'lib/ui/pages.dart',
      'lib/ui/shop_pages.dart',
      'lib/ui/prototype_pages.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');
    for (final banned in [
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

class _CoverageApi extends Fake implements SaydianApi {
  @override
  Future<Map<String, Object?>> getSingleArticle(int id) async => {
    'id': id,
    'title': switch (id) {
      2 => '用户协议',
      3 => '隐私政策',
      _ => '关于赛电',
    },
    'content': '<p>赛电健康服务说明</p>',
  };
}

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
