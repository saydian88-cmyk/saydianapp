import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/wearable_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methods = MethodChannel('cc.saidian/test_wearable_methods');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, null);
  });

  test('a timed out device command releases the serial queue', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (call) async {
          if (call.method == 'startSport') {
            return Completer<Object?>().future;
          }
          return 1;
        });
    final bridge = MethodChannelWearableBridge(
      methods: methods,
      operationTimeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      bridge.startSport(SportMode.walking),
      throwsA(isA<TimeoutException>()),
    );
    await expectLater(bridge.stopSport(), completes);
  });

  test('a timed out history sync releases the serial queue', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methods, (call) async {
          if (call.method == 'syncHealthData') {
            return Completer<List<Object?>>().future;
          }
          return <Object?>[];
        });
    final bridge = MethodChannelWearableBridge(
      methods: methods,
      syncTimeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      bridge.syncHealthData(),
      throwsA(isA<TimeoutException>()),
    );
    await expectLater(bridge.readSportRecords(), completes);
  });

  test(
    'pulls connected device details and preserves a null disconnect',
    () async {
      var connected = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methods, (call) async {
            if (call.method != 'getDeviceDetails' || !connected) return null;
            return <Object?, Object?>{
              'id': '38:23:A4:5E:CA:69',
              'name': 'SD-watch-W9S',
              'firmwareVersion': '00.20.01',
            };
          });
      final bridge = MethodChannelWearableBridge(methods: methods);

      final details = await bridge.getConnectedDeviceDetails();
      expect(details?.id, '38:23:A4:5E:CA:69');
      expect(details?.firmwareVersion, '00.20.01');

      connected = false;
      expect(await bridge.getConnectedDeviceDetails(), isNull);
    },
  );
}
