import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/yucheng_product_client.dart';
import 'package:saydian_app/services/yucheng_wearable_bridge.dart';

void main() {
  test(
    'disconnects when connected model is outside Yucheng allowlist',
    () async {
      final client = _FakeYuchengClient(
        modelName: 'YC Ring',
        scannedName: 'YC Ring',
      );
      final bridge = YuchengWearableBridge(
        client: client,
        initialHealthSettleDelay: Duration.zero,
      );
      await bridge.scanDevices();
      await expectLater(
        bridge.connect('YC-01', profile: _profile),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'YUCHENG_MODEL_MISMATCH',
          ),
        ),
      );
      expect(client.disconnectCount, 0);
    },
  );

  test('maps unavailable operation to FEATURE_UNSUPPORTED', () async {
    final client = _FakeYuchengClient(
      modelName: 'W8 Ultra',
      measurementStatus: 2,
    );
    final bridge = YuchengWearableBridge(
      client: client,
      initialHealthSettleDelay: Duration.zero,
    );
    await bridge.scanDevices();
    await bridge.connect('YC-01', profile: _profile);
    await expectLater(
      bridge.startMeasurement(HealthMetric.heartRate),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'FEATURE_UNSUPPORTED',
        ),
      ),
    );
  });

  test('accepts a suffixed W8S as a supported Yucheng model', () async {
    final client = _FakeYuchengClient(modelName: 'w8s 4DE9');
    final bridge = YuchengWearableBridge(
      client: client,
      initialHealthSettleDelay: Duration.zero,
    );

    await bridge.scanDevices();
    await bridge.connect('YC-01', profile: _profile);

    expect(client.disconnectCount, 0);
    expect(client.modelCalls, 0);
  });

  test('preserves the vendor MAC separately from the iOS identifier', () async {
    final client = _FakeYuchengClient(modelName: 'W8S');
    final bridge = YuchengWearableBridge(
      client: client,
      initialHealthSettleDelay: Duration.zero,
    );

    final device = (await bridge.scanDevices()).single;

    expect(device.id, 'YC-01');
    expect(device.hardwareAddress, '07:43:00:00:4D:E9');
    expect(device.macAddress, '07:43:00:00:4D:E9');
  });

  test('times out a Yucheng history read instead of hanging sync', () async {
    final client = _FakeYuchengClient(
      modelName: 'W8S',
      healthResult:
          Completer<YuchengOperationResult<List<Map<String, Object?>>>>()
              .future,
    );
    final bridge = YuchengWearableBridge(
      client: client,
      healthReadTimeout: const Duration(milliseconds: 10),
      initialHealthSettleDelay: Duration.zero,
    );
    await bridge.scanDevices();
    await bridge.connect('YC-01', profile: _profile);

    await expectLater(
      bridge.syncHealthData(),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'YUCHENG_SYNC_TIMEOUT',
        ),
      ),
    );
  });

  test('maps raw native bluetooth state events', () async {
    final client = _FakeYuchengClient(modelName: 'W8S');
    final bridge = YuchengWearableBridge(
      client: client,
      initialHealthSettleDelay: Duration.zero,
    );
    await bridge.scanDevices();
    final disconnected = bridge.events.first;

    client.emit({'bluetoothStateChange': 4});

    expect((await disconnected).type, 'disconnected');
  });
}

const _profile = WearableUserProfile(
  gender: 1,
  heightCm: 175,
  weightKg: 70,
  birthYear: 1996,
  age: 30,
  targetSteps: 10000,
);

class _FakeYuchengClient implements YuchengProductClient {
  _FakeYuchengClient({
    required this.modelName,
    this.scannedName = 'W8 Ultra',
    this.measurementStatus = 0,
    this.healthResult,
  });
  final String modelName;
  final String scannedName;
  final int measurementStatus;
  final Future<YuchengOperationResult<List<Map<String, Object?>>>>?
  healthResult;
  int disconnectCount = 0;
  int modelCalls = 0;
  final _events = StreamController<Map<String, Object?>>.broadcast();
  @override
  Stream<Map<String, Object?>> get events => _events.stream;
  @override
  Future<void> initialize({
    required bool reconnectEnabled,
    required bool logEnabled,
  }) async {}
  @override
  Future<List<Map<String, Object?>>> scan() async => [
    {
      'identifier': 'YC-01',
      'name': scannedName,
      'rssi': -40,
      'hardwareAddress': '07:43:00:00:4D:E9',
    },
  ];
  @override
  Future<void> stopScan() async {}
  @override
  Future<bool> connect(String identifier) async => true;
  @override
  Future<void> disconnect() async {
    disconnectCount++;
  }

  @override
  Future<YuchengOperationResult<String>> model() async {
    modelCalls++;
    return YuchengOperationResult(0, modelName);
  }

  @override
  Future<YuchengOperationResult<String>> firmware() async =>
      const YuchengOperationResult(0, '1.0');
  @override
  Future<Map<String, Object?>> capabilities() async => {
    'isSupportHeartRate': true,
  };
  @override
  Future<YuchengOperationResult<void>> syncTime() async =>
      const YuchengOperationResult(0, null);
  @override
  Future<YuchengOperationResult<void>> setUserProfile({
    required int height,
    required int weight,
    required int age,
    required int gender,
  }) async => const YuchengOperationResult(0, null);
  @override
  Future<YuchengOperationResult<void>> setStepGoal(int steps) async =>
      const YuchengOperationResult(0, null);
  @override
  Future<YuchengOperationResult<List<Map<String, Object?>>>> health(int type) =>
      healthResult ?? Future.value(const YuchengOperationResult(0, []));

  void emit(Map<String, Object?> event) => _events.add(event);
  @override
  Future<YuchengOperationResult<void>> measure({
    required bool enabled,
    required int type,
  }) async => YuchengOperationResult(measurementStatus, null);
  @override
  Future<YuchengOperationResult<void>> sport({
    required int state,
    required int type,
  }) async => const YuchengOperationResult(0, null);
  @override
  Future<YuchengOperationResult<void>> setHealthMonitoring(
    bool enabled,
  ) async => const YuchengOperationResult(0, null);
  @override
  Future<YuchengOperationResult<void>> setHeartRateAlarm(int value) async =>
      const YuchengOperationResult(0, null);
  @override
  Future<YuchengOperationResult<void>> findDevice() async =>
      const YuchengOperationResult(0, null);
  @override
  Future<YuchengOperationResult<void>> camera(bool enabled) async =>
      const YuchengOperationResult(0, null);
}
