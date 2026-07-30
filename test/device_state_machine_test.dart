import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/device_state_machine.dart';
import 'package:saydian_app/domain/models.dart';

void main() {
  group('DeviceStateMachine', () {
    test('accepts the production connection path', () {
      final machine = DeviceStateMachine();

      machine
        ..transition(DeviceConnectionState.scanning)
        ..transition(DeviceConnectionState.connecting)
        ..transition(DeviceConnectionState.authenticating)
        ..transition(DeviceConnectionState.syncing)
        ..transition(DeviceConnectionState.ready)
        ..transition(DeviceConnectionState.measuring)
        ..transition(DeviceConnectionState.ready)
        ..transition(DeviceConnectionState.disconnected);

      expect(machine.state, DeviceConnectionState.disconnected);
      machine.dispose();
    });

    test('rejects measuring before a device is ready', () {
      final machine = DeviceStateMachine();

      expect(
        () => machine.transition(DeviceConnectionState.measuring),
        throwsStateError,
      );
      machine.dispose();
    });
  });

  test('SerialOperationQueue never overlaps device operations', () async {
    final queue = SerialOperationQueue();
    final order = <String>[];

    final first = queue.run(() async {
      order.add('first:start');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      order.add('first:end');
    });
    final second = queue.run(() async {
      order.add('second:start');
      order.add('second:end');
    });

    await Future.wait([first, second]);
    expect(order, ['first:start', 'first:end', 'second:start', 'second:end']);
  });
}
