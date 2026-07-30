import 'dart:async';

import 'models.dart';

class DeviceStateMachine {
  DeviceStateMachine({
    DeviceConnectionState initial = DeviceConnectionState.disconnected,
  }) : _state = initial;

  static const _allowed = <DeviceConnectionState, Set<DeviceConnectionState>>{
    DeviceConnectionState.disconnected: {
      DeviceConnectionState.scanning,
      DeviceConnectionState.connecting,
      DeviceConnectionState.error,
    },
    DeviceConnectionState.scanning: {
      DeviceConnectionState.connecting,
      DeviceConnectionState.disconnected,
      DeviceConnectionState.error,
    },
    DeviceConnectionState.connecting: {
      DeviceConnectionState.authenticating,
      DeviceConnectionState.disconnected,
      DeviceConnectionState.error,
    },
    DeviceConnectionState.authenticating: {
      DeviceConnectionState.syncing,
      DeviceConnectionState.disconnected,
      DeviceConnectionState.error,
    },
    DeviceConnectionState.syncing: {
      DeviceConnectionState.ready,
      DeviceConnectionState.disconnected,
      DeviceConnectionState.error,
    },
    DeviceConnectionState.ready: {
      DeviceConnectionState.syncing,
      DeviceConnectionState.measuring,
      DeviceConnectionState.disconnected,
      DeviceConnectionState.error,
    },
    DeviceConnectionState.measuring: {
      DeviceConnectionState.ready,
      DeviceConnectionState.disconnected,
      DeviceConnectionState.error,
    },
    DeviceConnectionState.error: {
      DeviceConnectionState.disconnected,
      DeviceConnectionState.scanning,
      DeviceConnectionState.connecting,
    },
  };

  final _changes = StreamController<DeviceConnectionState>.broadcast();
  DeviceConnectionState _state;

  DeviceConnectionState get state => _state;
  Stream<DeviceConnectionState> get changes => _changes.stream;

  void transition(DeviceConnectionState next) {
    if (next == _state) return;
    if (!(_allowed[_state]?.contains(next) ?? false)) {
      throw StateError(
        'Invalid device transition: ${_state.name} → ${next.name}',
      );
    }
    _state = next;
    _changes.add(next);
  }

  void dispose() => _changes.close();
}

class SerialOperationQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
