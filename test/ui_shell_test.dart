import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/feature_models.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/api_client.dart';
import 'package:saydian_app/services/app_controller.dart';
import 'package:saydian_app/services/local_health_store.dart';
import 'package:saydian_app/services/secure_vault.dart';
import 'package:saydian_app/services/wearable_bridge.dart';
import 'package:saydian_app/ui/app_theme.dart';
import 'package:saydian_app/ui/health_trend_page.dart';
import 'package:saydian_app/ui/pages.dart';
import 'package:saydian_app/ui/prototype_pages.dart';

void main() {
  testWidgets('three-tab health shell exposes the redesigned home flows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    )..enterPreview();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => AppShell(controller: controller),
        ),
      ),
    );

    expect(find.byKey(const Key('dashboard-ai-assistant')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-functions')), findsOneWidget);
    expect(find.text('远程关爱'), findsOneWidget);
    expect(find.text('健康百科'), findsOneWidget);
    expect(find.text('健康预警'), findsOneWidget);
    expect(find.text('赛电商城'), findsOneWidget);

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.destinations, hasLength(3));
    expect(
      navigationBar.destinations.cast<NavigationDestination>().map(
        (destination) => destination.label,
      ),
      ['健康', '设备', '我的'],
    );

    await tester.tap(find.text('健康百科'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('article-category-page')), findsOneWidget);
    expect(find.byKey(const Key('article-category-all')), findsOneWidget);
    expect(find.text('心脑健康'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('赛电商城'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shop-page')), findsOneWidget);
    expect(find.text('此功能暂时无法使用，请稍后再试'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('全部数据'));
    await tester.tap(find.text('全部数据'));
    await tester.pumpAndSettle();
    expect(find.text('全部健康数据'), findsOneWidget);
    expect(find.text('健康数据总览'), findsOneWidget);
    expect(find.byKey(const Key('health-sport-entries')), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('health-sport-entries')),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('跑步'), findsOneWidget);
    expect(find.text('步行'), findsOneWidget);
    expect(find.text('骑行'), findsOneWidget);
    expect(find.text('徒步'), findsOneWidget);
    expect(find.text('运动记录'), findsOneWidget);

    const homeMetrics = [
      'bloodPressure',
      'heartRate',
      'bloodOxygen',
      'bodyTemperature',
      'ecg',
      'hrv',
    ];
    for (final metric in homeMetrics) {
      expect(find.byKey(ValueKey('health-metric-$metric')), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('health-metric-bloodGlucose')),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('health-metric-heartRate')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('health-metric-heartRate')));
    await tester.pumpAndSettle();
    expect(find.text('心率分析'), findsOneWidget);
    expect(find.text('连接支持该指标的手表后测量'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    controller.selectTab(1);
    await tester.pump();
    expect(find.widgetWithText(FilledButton, '开始查找'), findsOneWidget);

    controller.selectTab(2);
    await tester.pump();
    expect(find.byKey(const Key('my-page')), findsOneWidget);
    expect(find.text('我的订单'), findsOneWidget);

    for (var tab = 0; tab < 3; tab++) {
      controller.selectTab(tab);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'tab $tab overflowed');
    }
  });

  testWidgets('core tabs remain overflow-free at 375 x 812', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    )..enterPreview();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => AppShell(controller: controller),
        ),
      ),
    );

    for (var tab = 0; tab < 3; tab++) {
      controller.selectTab(tab);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'tab $tab overflowed');
    }
  });

  testWidgets('P40 Pro viewport and enlarged text remain overflow-free', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(362, 797));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    )..enterPreview();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => AppShell(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-ai-assistant')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('health-metric-heartRate')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('health-metric-heartRate')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('three tabs remain usable at 2x system text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(362, 797));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    )..enterPreview();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => AppShell(controller: controller),
        ),
      ),
    );

    for (var tab = 0; tab < 3; tab++) {
      controller.selectTab(tab);
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '2x text tab $tab overflowed',
      );
    }
  });

  testWidgets('article HTML keeps text and inline images', (tester) async {
    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: ArticleDetailPage(
          controller: controller,
          article: const {
            'title': '百科图片测试',
            'content':
                '<p>第一段说明</p><img src="https://example.invalid/one.png"><p>第二段说明</p><img src="/two.png">',
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('第一段说明'), findsOneWidget);
    expect(find.text('第二段说明'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('article-content-image-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('article-content-image-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('article pages distinguish loading failures from empty data', (
    tester,
  ) async {
    final controller = AppController(
      MemorySessionVault(),
      _FailingArticleApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: ArticleListPage(controller: controller, title: '健康百科'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('健康百科加载失败'), findsOneWidget);
    expect(find.byKey(const Key('article-retry')), findsOneWidget);
    expect(find.text('该分类暂无百科内容'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: ArticleDetailPage(
          controller: controller,
          article: const {'id': 7, 'title': '详情加载测试'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('健康百科加载失败'), findsOneWidget);
    expect(find.byKey(const Key('article-retry')), findsOneWidget);
    expect(find.text('文章详情暂未返回正文内容。'), findsNothing);
  });

  testWidgets('health analysis remains usable at 2x system text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(362, 797));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: HealthTrendPage(
          controller: controller,
          metric: HealthMetric.heartRate,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('心率分析'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back stops an active watch measurement', (tester) async {
    final wearable = _TrackingMeasurementWearable();
    final controller =
        AppController(
            MemorySessionVault(),
            _NoopApi(),
            MemoryHealthStore(),
            wearable,
          )
          ..connectedDevice = const DeviceInfo(id: 'watch-1', name: 'QA Watch')
          ..capabilities = const DeviceCapabilities(
            metrics: {HealthMetric.heartRate},
          );
    for (final state in const [
      DeviceConnectionState.scanning,
      DeviceConnectionState.connecting,
      DeviceConnectionState.authenticating,
      DeviceConnectionState.syncing,
      DeviceConnectionState.ready,
    ]) {
      controller.deviceMachine.transition(state);
    }
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: AllHealthDataPage(controller: controller),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('手动测量').first);
    await tester.pump();
    await tester.pump();
    expect(find.text('心率测量'), findsOneWidget);
    expect(wearable.starts, 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('心率测量'), findsNothing);
    expect(wearable.stops, 1);
    expect(controller.deviceState, DeviceConnectionState.ready);
  });

  test(
    'measurement startup failure returns false and restores ready state',
    () async {
      final controller =
          AppController(
              MemorySessionVault(),
              _NoopApi(),
              MemoryHealthStore(),
              _FailingMeasurementWearable(),
            )
            ..connectedDevice = const DeviceInfo(
              id: 'watch-1',
              name: 'QA Watch',
            )
            ..capabilities = const DeviceCapabilities(
              metrics: {HealthMetric.heartRate},
            );
      for (final state in const [
        DeviceConnectionState.scanning,
        DeviceConnectionState.connecting,
        DeviceConnectionState.authenticating,
        DeviceConnectionState.syncing,
        DeviceConnectionState.ready,
      ]) {
        controller.deviceMachine.transition(state);
      }
      addTearDown(controller.dispose);

      expect(
        await controller.startMeasurement(HealthMetric.heartRate),
        isFalse,
      );
      expect(controller.deviceState, DeviceConnectionState.ready);
      expect(controller.errorMessage, contains('心率测量失败'));
    },
  );

  testWidgets('health warning settings persist all three alarm switches', (
    tester,
  ) async {
    final vault = MemorySessionVault();
    final controller = AppController(
      vault,
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: HealthWarningPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('warning-heart-rate-switch')));
    await tester.tap(find.byKey(const Key('warning-blood-pressure-switch')));
    await tester.tap(find.byKey(const Key('warning-temperature-switch')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const Key('warning-save')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('warning-save')));
    await tester.pump();

    expect(vault.healthWarningSettings.heartRateEnabled, isTrue);
    expect(vault.healthWarningSettings.bloodPressureEnabled, isTrue);
    expect(vault.healthWarningSettings.temperatureEnabled, isTrue);
    expect(find.text('健康预警设置已保存'), findsOneWidget);
  });

  testWidgets('not-worn watch error stops progress and offers retry', (
    tester,
  ) async {
    final wearable = _EventMeasurementWearable();
    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      wearable,
    );
    await controller.initialize();
    controller.connectedDevice = const DeviceInfo(id: 'watch-1', name: 'W9S');
    controller.capabilities = const DeviceCapabilities(
      metrics: {HealthMetric.heartRate},
    );
    for (final state in const [
      DeviceConnectionState.scanning,
      DeviceConnectionState.connecting,
      DeviceConnectionState.authenticating,
      DeviceConnectionState.syncing,
      DeviceConnectionState.ready,
    ]) {
      controller.deviceMachine.transition(state);
    }
    addTearDown(() async {
      controller.dispose();
      await wearable.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: AllHealthDataPage(controller: controller),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('手动测量').first);
    await tester.pump();
    wearable.emit(
      const WearableEvent(
        type: 'error',
        payload: {'code': 'HEART_NOT_WORN', 'message': '请正确佩戴手表后重新测量心率'},
      ),
    );
    await tester.pump();

    expect(find.text('请正确佩戴手表后重新测量心率'), findsOneWidget);
    expect(find.text('重新测量'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(controller.deviceState, DeviceConnectionState.ready);
  });

  test(
    'new threshold-exceeding wearable record raises a global alert',
    () async {
      final wearable = _EventMeasurementWearable();
      final vault = MemorySessionVault()
        ..healthWarningSettings = const HealthWarningSettings(
          heartRateEnabled: true,
          heartRateUpper: 100,
        );
      final controller = AppController(
        vault,
        _NoopApi(),
        MemoryHealthStore(),
        wearable,
      );
      await controller.initialize();
      addTearDown(() async {
        controller.dispose();
        await wearable.close();
      });

      wearable.emit(
        WearableEvent(
          type: 'healthRecord',
          payload: HealthRecord(
            id: 'warning-heart-1',
            metric: HealthMetric.heartRate,
            values: const {'value': 128},
            unit: 'bpm',
            measuredAt: DateTime.now().toUtc(),
            timezone: '+08:00',
            deviceId: 'W9S',
            firmwareVersion: '00.20.01',
            quality: 'good',
            source: MeasurementSource.wearable,
            rawVersion: 1,
          ).toJson(),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.activeHealthWarningAlert?.metric,
        HealthMetric.heartRate,
      );
      expect(controller.activeHealthWarningAlert?.message, contains('128 bpm'));
      expect(controller.healthWarningAlerts, hasLength(1));
    },
  );

  test(
    'unsupported health settings finish with a clear device state',
    () async {
      final controller = AppController(
        MemorySessionVault(),
        _NoopApi(),
        MemoryHealthStore(),
        _NoopWearable(),
      )..connectedDevice = const DeviceInfo(id: 'watch-1', name: 'QA Watch');
      addTearDown(controller.dispose);

      await controller.refreshDeviceSettings();

      expect(controller.autoMeasureSettings, isEmpty);
      expect(controller.heartRateWarningSupported, isFalse);
      expect(controller.deviceSettingsStatus, '当前手表未提供可设置的健康检测项目');
    },
  );

  testWidgets('health trend supports period switching and record details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final store = MemoryHealthStore();
    await store.initialize();
    await store.upsert([
      for (var index = 0; index < 3; index++)
        HealthRecord(
          id: 'heart-$index',
          metric: HealthMetric.heartRate,
          values: {'value': 68 + index * 4},
          unit: 'bpm',
          measuredAt: DateTime(now.year, now.month, now.day, 8 + index * 3),
          timezone: '+08:00',
          deviceId: 'ET488',
          firmwareVersion: 'test',
          quality: 'good',
          source: MeasurementSource.wearable,
          rawVersion: 1,
        ),
    ]);
    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      store,
      _NoopWearable(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: HealthTrendPage(
          controller: controller,
          metric: HealthMetric.heartRate,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('心率分析'), findsOneWidget);
    expect(find.text('平均值'), findsOneWidget);
    expect(find.text('3 条'), findsWidgets);

    await tester.tap(find.text('周'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text('选择查看日期'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final recordTiles = find.ancestor(
      of: find.text('72 bpm'),
      matching: find.byType(ListTile),
    );
    await tester.scrollUntilVisible(
      recordTiles,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(recordTiles.last);
    await tester.pumpAndSettle();
    expect(find.text('心率详情'), findsOneWidget);
  });
}

class _NoopApi implements SaydianApi, SaydianArticleApi {
  @override
  Future<List<Map<String, Object?>>> getArticleCategories({
    int parentId = 3,
  }) async => const [
    {'id': 31, 'pid': 3, 'title': '心脑健康'},
  ];

  @override
  Future<List<Map<String, Object?>>> getArticlesByCategory({
    int? categoryId,
    int page = 1,
  }) async => const [
    {'id': 7, 'title': 'QA 健康知识'},
  ];

  @override
  Future<Map<String, Object?>> addCare(String mobile) async => const {};

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<List<Map<String, Object?>>> getCareMembers() async => const [];

  @override
  Future<Map<String, Object?>> getCareMemberPreview({
    required int id,
    required String day,
  }) async => const {};

  @override
  Future<Map<String, Object?>> getMemberProfile() async => const {};

  @override
  Future<void> saveMemberProfile({
    required String nickname,
    required int gender,
    required String birthday,
    required double height,
    required double weight,
    String? headPortrait,
  }) async {}

  @override
  Future<Map<String, Object?>> getActivityGoals() async => const {};

  @override
  Future<void> saveActivityGoals({
    required int steps,
    required double distance,
    required int calories,
  }) async {}

  @override
  Future<List<Map<String, Object?>>> getArticles() async => const [];

  @override
  Future<Map<String, Object?>> getArticle(int id) async => const {};

  @override
  Future<Map<String, Object?>> getSingleArticle(int id) async => const {};

  @override
  Future<List<Map<String, Object?>>> getNotifications({int page = 1}) async =>
      const [];

  @override
  Future<Map<String, Object?>> getNotification(int id) async => const {};

  @override
  Future<List<Map<String, Object?>>> getAiMessages({
    required int app,
    int page = 1,
  }) async => const [];

  @override
  Future<Map<String, Object?>> sendAiMessage({
    required int app,
    required String message,
    String? sessionId,
  }) async => const {};

  @override
  Future<List<Map<String, Object?>>> getOrders({int? status}) async => const [];

  @override
  Future<Map<String, Object?>> getOrderDetail(int id) async => const {};

  @override
  Future<List<Map<String, Object?>>> getAddresses() async => const [];

  @override
  Future<Session> login(String username, String password) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<Session> register(String mobile, String password) =>
      throw UnimplementedError();

  @override
  Future<BatchUploadResult> uploadHealthBatch(SyncBatch batch) =>
      throw UnimplementedError();
}

class _NoopWearable implements WearableBridge {
  @override
  Future<Map<String, Object?>> readDeviceFeature(DeviceFeature feature) async =>
      const {};

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

  @override
  Future<Map<String, bool>> readAutoMeasureSettings() async => const {};

  @override
  Future<int?> readHeartRateWarning() async => null;

  @override
  Future<void> setAutoMeasureSetting(String type, bool enabled) async {}

  @override
  Future<void> setHeartRateWarning(int value) async {}

  @override
  Future<void> connect(
    String deviceId, {
    required WearableUserProfile profile,
  }) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<WearableEvent> get events => const Stream.empty();

  @override
  Future<DeviceCapabilities> getCapabilities() async =>
      const DeviceCapabilities(metrics: {});

  @override
  Future<List<DeviceInfo>> scanDevices() async => const [];

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> startMeasurement(HealthMetric metric) async {}

  @override
  Future<void> stopMeasurement(HealthMetric metric) async {}

  @override
  Future<void> startSport(SportMode mode) async {}

  @override
  Future<void> stopSport() async {}

  @override
  Future<List<SportRecord>> readSportRecords() async => const [];

  @override
  Future<List<HealthRecord>> syncHealthData({String? cursor}) async => const [];
}

class _TrackingMeasurementWearable extends _NoopWearable {
  int starts = 0;
  int stops = 0;

  @override
  Future<void> startMeasurement(HealthMetric metric) async {
    starts++;
  }

  @override
  Future<void> stopMeasurement(HealthMetric metric) async {
    stops++;
  }
}

class _EventMeasurementWearable extends _TrackingMeasurementWearable {
  final _events = StreamController<WearableEvent>.broadcast(sync: true);

  @override
  Stream<WearableEvent> get events => _events.stream;

  void emit(WearableEvent event) => _events.add(event);

  Future<void> close() => _events.close();
}

class _FailingArticleApi extends _NoopApi {
  @override
  Future<List<Map<String, Object?>>> getArticlesByCategory({
    int? categoryId,
    int page = 1,
  }) async {
    throw const ApiException('模拟网络不可用');
  }

  @override
  Future<Map<String, Object?>> getArticle(int id) async {
    throw const ApiException('模拟网络不可用');
  }
}

class _FailingMeasurementWearable extends _NoopWearable {
  @override
  Future<void> startMeasurement(HealthMetric metric) async {
    throw StateError('simulated start failure');
  }
}
