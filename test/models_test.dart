import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/models.dart';

void main() {
  test('HealthRecord preserves its canonical wire representation', () {
    final record = HealthRecord(
      id: 'bp-1',
      metric: HealthMetric.bloodPressure,
      values: const {'systolic': 120, 'diastolic': 78},
      unit: 'mmHg',
      measuredAt: DateTime.utc(2026, 7, 29, 8, 30),
      timezone: '+08:00',
      deviceId: 'device-1',
      firmwareVersion: '1.2.3',
      quality: 'good',
      source: MeasurementSource.wearable,
      rawVersion: 1,
    );

    final decoded = HealthRecord.fromJson(record.toJson());

    expect(decoded.id, record.id);
    expect(decoded.metric, HealthMetric.bloodPressure);
    expect(decoded.displayValue, '120/78');
    expect(decoded.values, record.values);
    expect(decoded.measuredAt, record.measuredAt);
  });

  test('CarePermission is private by default', () {
    final permission = CarePermission.privateByDefault('member-1');

    expect(permission.accepted, isFalse);
    expect(permission.metrics, isEmpty);
    expect(permission.canRead(HealthMetric.heartRate), isFalse);
  });

  test('expired care permission never grants access', () {
    final permission = CarePermission(
      memberId: 'member-1',
      metrics: const {HealthMetric.heartRate},
      accepted: true,
      expiresAt: DateTime.utc(2026),
    );

    expect(
      permission.canRead(
        HealthMetric.heartRate,
        now: DateTime.utc(2026, 7, 29),
      ),
      isFalse,
    );
  });
}
