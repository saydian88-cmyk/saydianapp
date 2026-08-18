import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/health_record_validation.dart';
import 'package:saydian_app/domain/models.dart';

void main() {
  group('wearable transport sanity', () {
    test('rejects SDK sentinel values but keeps completed measurements', () {
      expect(_record(HealthMetric.heartRate, {'value': 1}).isSane, isFalse);
      expect(_record(HealthMetric.heartRate, {'value': 78}).isSane, isTrue);
      expect(_record(HealthMetric.bloodOxygen, {'value': 1}).isSane, isFalse);
      expect(_record(HealthMetric.bloodOxygen, {'value': 97}).isSane, isTrue);
      expect(
        _record(HealthMetric.bloodPressure, {
          'systolic': 1,
          'diastolic': 1,
        }).isSane,
        isFalse,
      );
      expect(
        _record(HealthMetric.bloodPressure, {
          'systolic': 126,
          'diastolic': 79,
        }).isSane,
        isTrue,
      );
      expect(
        _record(HealthMetric.bodyTemperature, {'value': 1}).isSane,
        isFalse,
      );
      expect(
        _record(HealthMetric.bodyTemperature, {'value': 35.9}).isSane,
        isTrue,
      );
    });

    test('does not reinterpret manually entered data as an SDK sentinel', () {
      expect(
        _record(HealthMetric.heartRate, {
          'value': 1,
        }, source: MeasurementSource.manual).isSane,
        isTrue,
      );
    });
  });
}

HealthRecord _record(
  HealthMetric metric,
  Map<String, num> values, {
  MeasurementSource source = MeasurementSource.wearable,
}) => HealthRecord(
  id: '${metric.wireName}-${values.values.join('-')}',
  metric: metric,
  values: values,
  unit: metric.defaultUnit,
  measuredAt: DateTime.utc(2026, 8, 15),
  timezone: '+08:00',
  deviceId: 'W9S',
  firmwareVersion: 'test',
  quality: 'device_reported',
  source: source,
  rawVersion: 1,
);

extension on HealthRecord {
  bool get isSane => hasSaneWearableTransportValues(this);
}
