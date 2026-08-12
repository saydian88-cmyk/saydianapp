import 'package:flutter/services.dart';

import '../domain/device_state_machine.dart';
import '../domain/feature_models.dart';
import '../domain/models.dart';

abstract interface class WearableBridge {
  Stream<WearableEvent> get events;

  Future<List<DeviceInfo>> scanDevices();
  Future<void> stopScan();
  Future<void> connect(String deviceId, {required WearableUserProfile profile});
  Future<void> disconnect();
  Future<DeviceCapabilities> getCapabilities();
  Future<List<HealthRecord>> syncHealthData({String? cursor});
  Future<void> startMeasurement(HealthMetric metric);
  Future<void> stopMeasurement(HealthMetric metric);
  Future<void> startSport(SportMode mode);
  Future<void> stopSport();
  Future<List<SportRecord>> readSportRecords();
  Future<Map<String, bool>> readAutoMeasureSettings();
  Future<void> setAutoMeasureSetting(String type, bool enabled);
  Future<int?> readHeartRateWarning();
  Future<void> setHeartRateWarning(int value);
  Future<Map<String, Object?>> readDeviceFeature(DeviceFeature feature);
  Future<void> writeDeviceFeature(
    DeviceFeature feature,
    Map<String, Object?> values,
  );
  Future<void> triggerDeviceAction(
    DeviceFeature feature, {
    bool enabled = true,
  });
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
  static const _deviceFeatureTimeout = Duration(seconds: 20);
  static const _watchFaceTimeout = Duration(minutes: 3);

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
  Future<void> stopScan() => _invoke<void>('stopScan');

  @override
  Future<void> connect(
    String deviceId, {
    required WearableUserProfile profile,
  }) => _queue.run(
    () => _invoke<void>('connect', {
      'deviceId': deviceId,
      'profile': profile.toMap(),
    }),
  );

  @override
  Future<void> disconnect() => _invoke<void>('disconnect');

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

  @override
  Future<void> startSport(SportMode mode) =>
      _queue.run(() => _invoke<void>('startSport', {'mode': mode.wireName}));

  @override
  Future<void> stopSport() => _queue.run(() => _invoke<void>('stopSport'));

  @override
  Future<List<SportRecord>> readSportRecords() => _queue.run(() async {
    final result = await _invoke<List<Object?>>('readSportRecords') ?? const [];
    return result
        .whereType<Map<Object?, Object?>>()
        .map(SportRecord.fromMap)
        .toList();
  });

  @override
  Future<Map<String, bool>> readAutoMeasureSettings() => _queue.run(() async {
    final result =
        await _invoke<Map<Object?, Object?>>('readAutoMeasureSettings') ??
        const {};
    return result.map((key, value) => MapEntry('$key', value == true));
  });

  @override
  Future<void> setAutoMeasureSetting(String type, bool enabled) => _queue.run(
    () => _invoke<void>('setAutoMeasureSetting', {
      'type': type,
      'enabled': enabled,
    }),
  );

  @override
  Future<int?> readHeartRateWarning() =>
      _queue.run(() => _invoke<int>('readHeartRateWarning'));

  @override
  Future<void> setHeartRateWarning(int value) =>
      _queue.run(() => _invoke<void>('setHeartRateWarning', {'value': value}));

  @override
  Future<Map<String, Object?>> readDeviceFeature(DeviceFeature feature) =>
      _queue.run(() async {
        final result =
            await _invoke<Map<Object?, Object?>>('readDeviceFeature', {
              'feature': feature.wireName,
            }).timeout(
              feature == DeviceFeature.watchFaces ||
                      feature == DeviceFeature.photoWatchFace
                  ? _watchFaceTimeout
                  : _deviceFeatureTimeout,
            ) ??
            const <Object?, Object?>{};
        return result.map((key, value) => MapEntry('$key', value));
      });

  @override
  Future<void> writeDeviceFeature(
    DeviceFeature feature,
    Map<String, Object?> values,
  ) => _queue.run(
    () =>
        _invoke<void>('writeDeviceFeature', {
          'feature': feature.wireName,
          'values': values,
        }).timeout(
          feature == DeviceFeature.watchFaces ||
                  feature == DeviceFeature.photoWatchFace
              ? _watchFaceTimeout
              : _deviceFeatureTimeout,
        ),
  );

  @override
  Future<void> triggerDeviceAction(
    DeviceFeature feature, {
    bool enabled = true,
  }) => _queue.run(
    () => _invoke<void>('triggerDeviceAction', {
      'feature': feature.wireName,
      'enabled': enabled,
    }).timeout(_deviceFeatureTimeout),
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
