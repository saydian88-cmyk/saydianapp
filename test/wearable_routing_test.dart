import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/feature_models.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/wearable_bridge.dart';
import 'package:saydian_app/services/wearable_routing.dart';

void main() {
  test('matches only the five normalized W8 device names', () {
    expect(W8DeviceClassifier.matches('W8'), isTrue);
    expect(W8DeviceClassifier.matches('w8s'), isTrue);
    expect(W8DeviceClassifier.matches(' W8  Pro '), isTrue);
    expect(W8DeviceClassifier.matches('W8-Ultra'), isTrue);
    expect(W8DeviceClassifier.matches('w8 ultra-r'), isTrue);
    expect(W8DeviceClassifier.matches('W80'), isFalse);
    expect(W8DeviceClassifier.matches('W8 Pro Max'), isFalse);
  });

  test('scopes IDs without losing the vendor identifier', () {
    final routed = RoutedDevice.fromScan(
      transport: WearableTransport.yucheng,
      nativeIdentifier: 'A1-B2',
      name: 'W8 Ultra',
    );

    expect(routed.display.id, 'yucheng:A1-B2');
    expect(routed.nativeIdentifier, 'A1-B2');
    expect(routed.transport, WearableTransport.yucheng);
  });

  test('prefers Yucheng for a W8 seen by both SDKs', () async {
    final veepoo = _FakeWearableBridge(
      scanned: const [
        DeviceInfo(id: 'AA:01', name: 'W8 Ultra'),
        DeviceInfo(id: 'AA:02', name: 'VP-100'),
      ],
    );
    final yucheng = _FakeWearableBridge(
      scanned: const [DeviceInfo(id: 'AA:01', name: 'W8 Ultra')],
    );
    final bridge = RoutedWearableBridge(veepoo: veepoo, yucheng: yucheng);

    final devices = await bridge.scanDevices();

    expect(devices.map((item) => item.id), contains('yucheng:AA:01'));
    expect(devices.map((item) => item.id), isNot(contains('veepoo:AA:01')));
    expect(devices.map((item) => item.id), contains('veepoo:AA:02'));
  });

  test('locks every later operation to the transport that connected', () async {
    final veepoo = _FakeWearableBridge(scanned: const []);
    final yucheng = _FakeWearableBridge(
      scanned: const [DeviceInfo(id: 'YC-1', name: 'W8S')],
    );
    final bridge = RoutedWearableBridge(veepoo: veepoo, yucheng: yucheng);

    await bridge.scanDevices();
    await bridge.connect('yucheng:YC-1', profile: _profile);
    await bridge.startMeasurement(HealthMetric.heartRate);

    expect(yucheng.connectCalls, ['YC-1']);
    expect(yucheng.measurementCalls, [HealthMetric.heartRate]);
    expect(veepoo.connectCalls, isEmpty);
    expect(veepoo.measurementCalls, isEmpty);
  });

  test('never connects a W8 only returned by Veepoo', () async {
    final bridge = RoutedWearableBridge(
      veepoo: _FakeWearableBridge(
        scanned: const [DeviceInfo(id: 'W8-1', name: 'W8')],
      ),
      yucheng: _FakeWearableBridge(scanned: const []),
    );

    final w8 = (await bridge.scanDevices()).single;

    await expectLater(
      bridge.connect(w8.id, profile: _profile),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'YUCHENG_DISCOVERY_MISMATCH',
        ),
      ),
    );
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

class _FakeWearableBridge extends Fake implements WearableBridge {
  _FakeWearableBridge({required this.scanned});

  final List<DeviceInfo> scanned;
  final _events = StreamController<WearableEvent>.broadcast();
  final List<String> connectCalls = [];
  final List<HealthMetric> measurementCalls = [];

  @override
  Stream<WearableEvent> get events => _events.stream;

  @override
  Future<List<DeviceInfo>> scanDevices() async => scanned;

  @override
  Future<void> connect(
    String deviceId, {
    required WearableUserProfile profile,
  }) async {
    connectCalls.add(deviceId);
  }

  @override
  Future<void> startMeasurement(HealthMetric metric) async {
    measurementCalls.add(metric);
  }
}
