import 'package:flutter/services.dart';

import '../domain/device_state_machine.dart';
import '../domain/models.dart';

abstract interface class WearableBridge {
  Stream<WearableEvent> get events;

  Future<List<DeviceInfo>> scanDevices();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<DeviceCapabilities> getCapabilities();
  Future<List<HealthRecord>> syncHealthData({String? cursor});
  Future<void> startMeasurement(HealthMetric metric);
  Future<void> stopMeasurement(HealthMetric metric);
}

class WearableSdkNotConfigured implements Exception {
  const WearableSdkNotConfigured([this.message = 'Veepoo 合作方 SDK 尚未配置']);

  final String message;

  @override
  String toString() => message;
}

class MethodChannelWearableBridge implements WearableBridge {
  MethodChannelWearableBridge({
    MethodChannel? methods,
    EventChannel? eventChannel,
  }) : _methods = methods ?? const MethodChannel('cc.saidian/wearable_methods'),
       _eventChannel =
           eventChannel ?? const EventChannel('cc.saidian/wearable_events');

  final MethodChannel _methods;
  final EventChannel _eventChannel;
  final SerialOperationQueue _queue = SerialOperationQueue();

  @override
  Stream<WearableEvent> get events => _eventChannel
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => WearableEvent.fromMap(event as Map<Object?, Object?>));

  @override
  Future<List<DeviceInfo>> scanDevices() => _queue.run(() async {
    final result = await _invoke<List<Object?>>('scanDevices') ?? const [];
    return result
        .whereType<Map<Object?, Object?>>()
        .map(DeviceInfo.fromMap)
        .toList();
  });

  @override
  Future<void> connect(String deviceId) =>
      _queue.run(() => _invoke<void>('connect', {'deviceId': deviceId}));

  @override
  Future<void> disconnect() => _queue.run(() => _invoke<void>('disconnect'));

  @override
  Future<DeviceCapabilities> getCapabilities() => _queue.run(() async {
    final result =
        await _invoke<Map<Object?, Object?>>('getCapabilities') ??
        const <Object?, Object?>{};
    return DeviceCapabilities.fromMap(result);
  });

  @override
  Future<List<HealthRecord>> syncHealthData({String? cursor}) => _queue.run(
    () async {
      final result =
          await _invoke<List<Object?>>('syncHealthData', {'cursor': cursor}) ??
          const [];
      return result
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) => HealthRecord.fromJson(
              item.map((key, value) => MapEntry('$key', value)),
            ),
          )
          .toList();
    },
  );

  @override
  Future<void> startMeasurement(HealthMetric metric) => _queue.run(
    () => _invoke<void>('startMeasurement', {'metric': metric.wireName}),
  );

  @override
  Future<void> stopMeasurement(HealthMetric metric) => _queue.run(
    () => _invoke<void>('stopMeasurement', {'metric': metric.wireName}),
  );

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      if (error.code == 'SDK_NOT_CONFIGURED') {
        throw WearableSdkNotConfigured(error.message ?? 'Veepoo SDK 未配置');
      }
      rethrow;
    } on MissingPluginException {
      throw const WearableSdkNotConfigured();
    }
  }
}
