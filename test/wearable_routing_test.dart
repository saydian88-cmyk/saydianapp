import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/wearable_bridge.dart';
import 'package:saydian_app/services/wearable_routing.dart';

void main() {
  test('matches supported normalized Yucheng model names', () {
    expect(YuchengDeviceClassifier.matches('W8'), isTrue);
    expect(YuchengDeviceClassifier.matches('w8s'), isTrue);
    expect(YuchengDeviceClassifier.matches('W8S 983F'), isTrue);
    expect(YuchengDeviceClassifier.matches('W8 983F'), isTrue);
    expect(YuchengDeviceClassifier.matches(' W8  Pro '), isTrue);
    expect(YuchengDeviceClassifier.matches('W8-Ultra'), isTrue);
    expect(YuchengDeviceClassifier.matches('w8 ultra-r'), isTrue);
    expect(YuchengDeviceClassifier.matches('W80'), isFalse);
    expect(YuchengDeviceClassifier.matches('W8 Pro Max'), isFalse);
    expect(YuchengDeviceClassifier.matches('W9S'), isFalse);
    expect(YuchengDeviceClassifier.matches('w9 s 1234'), isFalse);
    expect(YuchengDeviceClassifier.matches('W9'), isFalse);
    expect(YuchengDeviceClassifier.matches('VP-100'), isFalse);
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
      scanned: const [DeviceInfo(id: 'IOS-UUID-01', name: 'W8 Ultra')],
    );
    final bridge = RoutedWearableBridge(veepoo: veepoo, yucheng: yucheng);

    final devices = await bridge.scanDevices();

    expect(devices.map((item) => item.id), contains('yucheng:IOS-UUID-01'));
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

  test('hides a W8 only returned by Veepoo', () async {
    final bridge = RoutedWearableBridge(
      veepoo: _FakeWearableBridge(
        scanned: const [DeviceInfo(id: 'W8-1', name: 'W8')],
      ),
      yucheng: _FakeWearableBridge(scanned: const []),
    );

    expect(await bridge.scanDevices(), isEmpty);
  });

  test('keeps W9 and W9S devices on the Veepoo transport', () async {
    final bridge = RoutedWearableBridge(
      veepoo: _FakeWearableBridge(
        scanned: const [
          DeviceInfo(id: 'W9-1', name: 'W9 1001'),
          DeviceInfo(id: 'W9S-1', name: 'SD-watch-W9S'),
        ],
      ),
      yucheng: _FakeWearableBridge(scanned: const []),
    );

    final devices = await bridge.scanDevices();

    expect(devices, hasLength(2));
    expect(devices.map((device) => device.id), contains('veepoo:W9-1'));
    expect(devices.map((device) => device.id), contains('veepoo:W9S-1'));
  });

  test('drops live Veepoo W8 events and forwards the Yucheng event', () async {
    final veepoo = _FakeWearableBridge(scanned: const []);
    final yucheng = _FakeWearableBridge(scanned: const []);
    final bridge = RoutedWearableBridge(veepoo: veepoo, yucheng: yucheng);
    final received = <WearableEvent>[];
    final subscription = bridge.events.listen(received.add);

    veepoo.emitScan(
      const DeviceInfo(id: '07:43:00:00:4D:E9', name: 'w8s 4DE9'),
    );
    yucheng.emitScan(
      const DeviceInfo(id: '07:43:00:00:4D:E9', name: 'w8s 4DE9'),
    );
    await pumpEventQueue();

    expect(received, hasLength(1));
    expect(received.single.payload['id'], 'yucheng:07:43:00:00:4D:E9');
    await subscription.cancel();
    await bridge.dispose();
  });

  test(
    'discovers suffixed W8S through Yucheng and hides the Veepoo duplicate',
    () async {
      final bridge = RoutedWearableBridge(
        veepoo: _FakeWearableBridge(
          scanned: const [DeviceInfo(id: 'VP-W8S', name: 'w8s 4DE9')],
        ),
        yucheng: _FakeWearableBridge(
          scanned: const [DeviceInfo(id: 'YC-W8S', name: 'w8s 4DE9')],
        ),
      );

      final devices = await bridge.scanDevices();

      expect(devices, hasLength(1));
      expect(devices.single.id, 'yucheng:YC-W8S');
      expect(devices.single.name, 'w8s 4DE9');
    },
  );
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

  void emitScan(DeviceInfo device) {
    _events.add(WearableEvent(type: 'scanDevice', payload: device.toJson()));
  }

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
