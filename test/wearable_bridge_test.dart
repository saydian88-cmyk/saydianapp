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
}
