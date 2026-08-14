import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/feature_models.dart';
import '../domain/models.dart';
import 'wearable_bridge.dart';
import 'wearable_routing.dart';
import 'yucheng_payload_mapper.dart';
import 'yucheng_product_client.dart';

class YuchengWearableBridge implements WearableBridge {
  YuchengWearableBridge({
    YuchengProductClient? client,
    this.healthReadTimeout = const Duration(seconds: 8),
    this.initialHealthSettleDelay = const Duration(seconds: 3),
  }) : _client = client ?? PluginYuchengProductClient();
  final YuchengProductClient _client;
  final Duration healthReadTimeout;
  final Duration initialHealthSettleDelay;
  final _events = StreamController<WearableEvent>.broadcast();
  bool _initialized = false;
  String? _deviceId;
  final String _firmware = '';
  DeviceCapabilities? _capabilities;
  final Map<String, String> _scannedNames = {};
  bool _needsInitialHealthSettle = false;

  @override
  Stream<WearableEvent> get events => _events.stream;

  Future<void> _initialize() async {
    if (_initialized) return;
    await _client.initialize(reconnectEnabled: true, logEnabled: false);
    _client.events.listen(_handleEvent);
    _initialized = true;
  }

  @override
  Future<List<DeviceInfo>> scanDevices() async {
    await _initialize();
    final devices = (await _client.scan())
        .map(
          (row) => DeviceInfo(
            id: '${row['identifier'] ?? ''}',
            name: '${row['name'] ?? ''}',
            rssi: (row['rssi'] as num?)?.toInt(),
            firmwareVersion: row['firmwareVersion']?.toString(),
          ),
        )
        .where((d) => d.id.isNotEmpty)
        .toList();
    _scannedNames
      ..clear()
      ..addEntries(devices.map((device) => MapEntry(device.id, device.name)));
    return devices;
  }

  @override
  Future<void> stopScan() async {
    await _initialize();
    await _client.stopScan();
  }

  @override
  Future<void> connect(
    String deviceId, {
    required WearableUserProfile profile,
  }) async {
    await _initialize();
    final scannedName = _scannedNames[deviceId] ?? '';
    if (!YuchengDeviceClassifier.matches(scannedName)) {
      throw PlatformException(
        code: 'YUCHENG_MODEL_MISMATCH',
        message: '连接设备不是受支持的 Yuc 型号',
      );
    }
    final connected = await _client
        .connect(deviceId)
        .timeout(const Duration(seconds: 30), onTimeout: () => false);
    if (!connected) {
      throw PlatformException(
        code: 'YUCHENG_CONNECT_FAILED',
        message: '云创 SDK 连接失败',
      );
    }
    // The plugin starts its own model/MCU/feature queries when BLE reaches the
    // ready state. Issuing another model and setup sequence here can leave its
    // native command queue waiting forever. BLE authentication is therefore
    // the connection boundary; optional metadata is loaded separately.
    _deviceId = deviceId;
    _capabilities = _safeW8Capabilities;
    _needsInitialHealthSettle = true;
  }

  @override
  Future<void> disconnect() async {
    await _client.disconnect();
    _deviceId = null;
    _capabilities = null;
    _needsInitialHealthSettle = false;
  }

  @override
  Future<DeviceCapabilities> getCapabilities() async {
    _connectedId;
    return _capabilities ?? _safeW8Capabilities;
  }

  static const _safeW8Capabilities = DeviceCapabilities(
    metrics: {
      HealthMetric.steps,
      HealthMetric.distance,
      HealthMetric.calories,
      HealthMetric.sleep,
      HealthMetric.heartRate,
      HealthMetric.bloodPressure,
      HealthMetric.bloodOxygen,
    },
    features: {
      DeviceFeature.findWatch,
      DeviceFeature.camera,
      DeviceFeature.healthMonitoring,
    },
    integratedFeatures: {
      DeviceFeature.findWatch,
      DeviceFeature.camera,
      DeviceFeature.healthMonitoring,
    },
    supportsBackgroundSync: true,
  );

  @override
  Future<List<HealthRecord>> syncHealthData({String? cursor}) async {
    final id = _connectedId;
    if (_needsInitialHealthSettle) {
      _needsInitialHealthSettle = false;
      // Yuc/JL finishes its device-info handshake shortly after BLE reports
      // ready. Keep this vendor-specific delay inside the Yuc bridge so Vep
      // devices and unrelated UI flows are never held back.
      await Future<void>.delayed(initialHealthSettleDelay);
      if (_deviceId != id) {
        throw PlatformException(
          code: 'CONNECTION_DROPPED',
          message: '设备连接已断开',
        );
      }
    }
    final rows = <int, List<Map<String, Object?>>>{};
    for (final type in [
      YuchengHealthDataType.step,
      YuchengHealthDataType.sleep,
      YuchengHealthDataType.heartRate,
      YuchengHealthDataType.bloodPressure,
      YuchengHealthDataType.combined,
    ]) {
      final result = await _client
          .health(type)
          .timeout(
            healthReadTimeout,
            onTimeout: () => throw PlatformException(
              code: 'YUCHENG_SYNC_TIMEOUT',
              message: '云创 SDK 历史数据读取超时',
            ),
          );
      if (result.status == 0) {
        rows[type] = result.data ?? const [];
      } else if (result.status != 2) {
        _require(result);
      }
    }
    return YuchengPayloadMapper.healthRecords(
      deviceId: id,
      firmwareVersion: _firmware,
      rowsByType: rows,
    );
  }

  static const _measurements = {
    HealthMetric.heartRate: YuchengMeasurementType.heartRate,
    HealthMetric.bloodPressure: YuchengMeasurementType.bloodPressure,
    HealthMetric.bloodOxygen: YuchengMeasurementType.bloodOxygen,
    HealthMetric.bodyTemperature: YuchengMeasurementType.bodyTemperature,
  };
  @override
  Future<void> startMeasurement(HealthMetric metric) async {
    _connectedId;
    final type = _measurements[metric];
    if (type == null) throw _unsupported();
    _require(await _client.measure(enabled: true, type: type));
  }

  @override
  Future<void> stopMeasurement(HealthMetric metric) async {
    _connectedId;
    final type = _measurements[metric];
    if (type == null) throw _unsupported();
    _require(await _client.measure(enabled: false, type: type));
  }

  static const _sports = {
    SportMode.running: 0x0F,
    SportMode.walking: 0x10,
    SportMode.cycling: 0x03,
    SportMode.hiking: 0x1B,
  };
  @override
  Future<void> startSport(SportMode mode) async {
    _connectedId;
    _require(
      await _client.sport(state: YuchengSportState.start, type: _sports[mode]!),
    );
  }

  @override
  Future<void> stopSport() async {
    _connectedId;
    _require(await _client.sport(state: YuchengSportState.stop, type: 0));
  }

  @override
  Future<List<SportRecord>> readSportRecords() async {
    _connectedId;
    final r = await _client.health(YuchengHealthDataType.sportHistory);
    _require(r);
    return YuchengPayloadMapper.sportRecords(r.data ?? const []);
  }

  @override
  Future<Map<String, bool>> readAutoMeasureSettings() async =>
      throw _unsupported('云创 SDK 不提供健康监测读取接口');
  @override
  Future<void> setAutoMeasureSetting(String type, bool enabled) async {
    _connectedId;
    if (type != 'heart_rate') throw _unsupported();
    _require(await _client.setHealthMonitoring(enabled));
  }

  @override
  Future<int?> readHeartRateWarning() async =>
      throw _unsupported('云创 SDK 不提供心率预警读取接口');
  @override
  Future<void> setHeartRateWarning(int value) async {
    _connectedId;
    _require(await _client.setHeartRateAlarm(value));
  }

  @override
  Future<Map<String, Object?>> readDeviceFeature(DeviceFeature feature) async =>
      throw _unsupported('云创 SDK 不提供该设置的无损读取接口');
  @override
  Future<void> writeDeviceFeature(
    DeviceFeature feature,
    Map<String, Object?> values,
  ) async => throw _unsupported();
  @override
  Future<void> triggerDeviceAction(
    DeviceFeature feature, {
    bool enabled = true,
  }) async {
    _connectedId;
    if (feature == DeviceFeature.findWatch) {
      _require(await _client.findDevice());
    } else if (feature == DeviceFeature.camera) {
      _require(await _client.camera(enabled));
    } else {
      throw _unsupported();
    }
  }

  String get _connectedId =>
      _deviceId ??
      (throw PlatformException(code: 'NOT_CONNECTED', message: '请先连接手表'));
  void _require(YuchengOperationResult<Object?> result) {
    if (result.status == 2) throw _unsupported();
    if (result.status != 0) {
      throw PlatformException(
        code: 'YUCHENG_OPERATION_FAILED',
        message: '云创 SDK 操作失败',
      );
    }
  }

  static PlatformException _unsupported([
    String message = '当前 Yuc 设备或云创 SDK 不支持此功能',
  ]) => PlatformException(code: 'FEATURE_UNSUPPORTED', message: message);

  void _handleEvent(Map<String, Object?> event) {
    const nativeEventTypes = <String>{
      'bluetoothStateChange',
      'deviceRealHeartRate',
      'deviceRealBloodPressure',
      'deviceRealBloodOxygen',
      'deviceRealTemperature',
      'deviceControlPhotoStateChange',
      'deviceWatchFaceChange',
      'deviceJieLiWatchFaceChange',
    };
    final declaredType = '${event['type'] ?? event['eventType'] ?? ''}';
    final type = declaredType.isNotEmpty
        ? declaredType
        : event.keys.cast<String?>().firstWhere(
                nativeEventTypes.contains,
                orElse: () => null,
              ) ??
              '';
    final rawPayload = event['data'] ?? event[type];
    final payload = rawPayload is Map
        ? rawPayload.map((k, v) => MapEntry('$k', v))
        : <String, Object?>{'value': rawPayload};
    final mapped = switch (type) {
      'bluetoothStateChange' => WearableEvent(
        type: (payload['state'] ?? payload['value']) == 4
            ? 'disconnected'
            : 'state',
        payload: {
          'value': (payload['state'] ?? payload['value']) == 2
              ? 'ready'
              : 'connecting',
        },
      ),
      'deviceRealHeartRate' => WearableEvent(
        type: 'measurement',
        payload: {'metric': 'heart_rate', ...payload},
      ),
      'deviceRealBloodPressure' => WearableEvent(
        type: 'measurement',
        payload: {'metric': 'blood_pressure', ...payload},
      ),
      'deviceRealBloodOxygen' => WearableEvent(
        type: 'measurement',
        payload: {'metric': 'blood_oxygen', ...payload},
      ),
      'deviceRealTemperature' => WearableEvent(
        type: 'measurement',
        payload: {'metric': 'body_temperature', ...payload},
      ),
      'deviceControlPhotoStateChange' => WearableEvent(
        type: 'cameraShutter',
        payload: payload,
      ),
      'deviceWatchFaceChange' || 'deviceJieLiWatchFaceChange' => WearableEvent(
        type: 'deviceFeatureProgress',
        payload: {'feature': 'watch_faces', ...payload},
      ),
      _ => null,
    };
    if (mapped != null) _events.add(mapped);
  }
}
