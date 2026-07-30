import 'dart:convert';

enum DeviceConnectionState {
  disconnected,
  scanning,
  connecting,
  authenticating,
  syncing,
  ready,
  measuring,
  error,
}

enum HealthMetric {
  steps('steps', '步数', '步'),
  distance('distance', '距离', 'km'),
  calories('calories', '热量', 'kcal'),
  sleep('sleep', '睡眠', 'h'),
  heartRate('heart_rate', '心率', 'bpm'),
  bloodOxygen('blood_oxygen', '血氧', '%'),
  bloodPressure('blood_pressure', '血压', 'mmHg'),
  bodyTemperature('body_temperature', '体温', '℃'),
  ecg('ecg', '心电', ''),
  hrv('hrv', 'HRV', 'ms'),
  bodyComposition('body_composition', '身体成分', ''),
  bloodComposition('blood_composition', '血液成分', '');

  const HealthMetric(this.wireName, this.label, this.defaultUnit);

  final String wireName;
  final String label;
  final String defaultUnit;

  static HealthMetric fromWire(String value) => values.firstWhere(
    (metric) => metric.wireName == value,
    orElse: () => HealthMetric.steps,
  );
}

enum MeasurementSource { wearable, manual, imported }

class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.name,
    this.model,
    this.serialNumber,
    this.firmwareVersion,
    this.rssi,
    this.lastSyncAt,
  });

  final String id;
  final String name;
  final String? model;
  final String? serialNumber;
  final String? firmwareVersion;
  final int? rssi;
  final DateTime? lastSyncAt;

  factory DeviceInfo.fromMap(Map<Object?, Object?> map) => DeviceInfo(
    id: '${map['id'] ?? map['identifier'] ?? ''}',
    name: '${map['name'] ?? '赛电设备'}',
    model: map['model']?.toString(),
    serialNumber: map['serialNumber']?.toString(),
    firmwareVersion: map['firmwareVersion']?.toString(),
    rssi: map['rssi'] is num ? (map['rssi'] as num).toInt() : null,
    lastSyncAt: DateTime.tryParse('${map['lastSyncAt'] ?? ''}'),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'model': model,
    'serialNumber': serialNumber,
    'firmwareVersion': firmwareVersion,
    'rssi': rssi,
    'lastSyncAt': lastSyncAt?.toUtc().toIso8601String(),
  };
}

class DeviceCapabilities {
  const DeviceCapabilities({
    required this.metrics,
    this.supportsBackgroundSync = false,
    this.supportsWatchFaces = false,
    this.supportsOta = false,
  });

  final Set<HealthMetric> metrics;
  final bool supportsBackgroundSync;
  final bool supportsWatchFaces;
  final bool supportsOta;

  factory DeviceCapabilities.fromMap(Map<Object?, Object?> map) {
    final raw = map['metrics'];
    final metrics = raw is List
        ? raw.map((value) => HealthMetric.fromWire('$value')).toSet()
        : <HealthMetric>{};
    return DeviceCapabilities(
      metrics: metrics,
      supportsBackgroundSync: map['supportsBackgroundSync'] == true,
      supportsWatchFaces: map['supportsWatchFaces'] == true,
      supportsOta: map['supportsOta'] == true,
    );
  }

  bool supports(HealthMetric metric) => metrics.contains(metric);

  Map<String, Object?> toJson() => {
    'metrics': metrics.map((metric) => metric.wireName).toList(),
    'supportsBackgroundSync': supportsBackgroundSync,
    'supportsWatchFaces': supportsWatchFaces,
    'supportsOta': supportsOta,
  };
}

class HealthRecord {
  HealthRecord({
    required this.id,
    required this.metric,
    required this.values,
    required this.unit,
    required this.measuredAt,
    required this.timezone,
    required this.deviceId,
    required this.firmwareVersion,
    required this.quality,
    required this.source,
    required this.rawVersion,
  });

  final String id;
  final HealthMetric metric;
  final Map<String, num> values;
  final String unit;
  final DateTime measuredAt;
  final String timezone;
  final String deviceId;
  final String firmwareVersion;
  final String quality;
  final MeasurementSource source;
  final int rawVersion;

  factory HealthRecord.fromJson(Map<String, Object?> json) {
    final rawValues = json['values'];
    return HealthRecord(
      id: '${json['id']}',
      metric: HealthMetric.fromWire('${json['type']}'),
      values: rawValues is Map
          ? rawValues.map(
              (key, value) =>
                  MapEntry('$key', value is num ? value : num.parse('$value')),
            )
          : <String, num>{},
      unit: '${json['unit'] ?? ''}',
      measuredAt: DateTime.parse('${json['measuredAt']}').toUtc(),
      timezone: '${json['timezone'] ?? '+08:00'}',
      deviceId: '${json['deviceId'] ?? ''}',
      firmwareVersion: '${json['firmwareVersion'] ?? ''}',
      quality: '${json['quality'] ?? 'unknown'}',
      source: MeasurementSource.values.firstWhere(
        (source) => source.name == json['source'],
        orElse: () => MeasurementSource.wearable,
      ),
      rawVersion: (json['rawVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': metric.wireName,
    'values': values,
    'unit': unit,
    'measuredAt': measuredAt.toUtc().toIso8601String(),
    'timezone': timezone,
    'deviceId': deviceId,
    'firmwareVersion': firmwareVersion,
    'quality': quality,
    'source': source.name,
    'rawVersion': rawVersion,
  };

  String get displayValue {
    if (metric == HealthMetric.bloodPressure) {
      final systolic = values['systolic'];
      final diastolic = values['diastolic'];
      if (systolic != null && diastolic != null) {
        return '${_number(systolic)}/${_number(diastolic)}';
      }
    }
    final value =
        values['value'] ?? (values.isEmpty ? null : values.values.first);
    return value == null ? '--' : _number(value);
  }

  static String _number(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

  String encode() => jsonEncode(toJson());
}

class SyncBatch {
  const SyncBatch({required this.cursor, required this.records});

  final String? cursor;
  final List<HealthRecord> records;

  Map<String, Object?> toJson() => {
    'cursor': cursor,
    'records': records.map((record) => record.toJson()).toList(),
  };
}

class CarePermission {
  const CarePermission({
    required this.memberId,
    required this.metrics,
    required this.accepted,
    this.expiresAt,
  });

  factory CarePermission.privateByDefault(String memberId) => CarePermission(
    memberId: memberId,
    metrics: const <HealthMetric>{},
    accepted: false,
  );

  final String memberId;
  final Set<HealthMetric> metrics;
  final bool accepted;
  final DateTime? expiresAt;

  bool canRead(HealthMetric metric, {DateTime? now}) {
    if (!accepted || !metrics.contains(metric)) return false;
    if (expiresAt == null) return true;
    return expiresAt!.isAfter(now ?? DateTime.now());
  }
}

class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.memberId,
    required this.displayName,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String memberId;
  final String displayName;

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'memberId': memberId,
    'displayName': displayName,
  };

  factory Session.fromJson(Map<String, Object?> json) => Session(
    accessToken: '${json['accessToken']}',
    refreshToken: '${json['refreshToken']}',
    expiresAt: DateTime.parse('${json['expiresAt']}'),
    memberId: '${json['memberId']}',
    displayName: '${json['displayName']}',
  );
}

class WearableEvent {
  const WearableEvent({required this.type, required this.payload});

  final String type;
  final Map<String, Object?> payload;

  factory WearableEvent.fromMap(Map<Object?, Object?> map) => WearableEvent(
    type: '${map['type'] ?? 'unknown'}',
    payload: map.map((key, value) => MapEntry('$key', value)),
  );
}
