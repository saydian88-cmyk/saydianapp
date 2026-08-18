import 'models.dart';

/// Rejects values that cannot be a completed wearable measurement.
///
/// These are deliberately broad transport-sanity limits, not clinical
/// reference ranges. Their purpose is to keep SDK progress and error sentinel
/// values (for example `1`) out of local history and cloud synchronization.
bool hasSaneWearableTransportValues(HealthRecord record) {
  if (record.source != MeasurementSource.wearable) return true;

  return switch (record.metric) {
    HealthMetric.heartRate => _inRange(record.values['value'], 20, 300),
    HealthMetric.bloodOxygen => _inRange(record.values['value'], 2, 100),
    HealthMetric.bloodPressure => _hasSaneBloodPressure(record.values),
    HealthMetric.bodyTemperature => _inRange(record.values['value'], 20, 45),
    _ => true,
  };
}

bool _hasSaneBloodPressure(Map<String, num> values) {
  final systolic = values['systolic'];
  final diastolic = values['diastolic'];
  return _inRange(systolic, 60, 300) &&
      _inRange(diastolic, 20, 200) &&
      systolic! > diastolic!;
}

bool _inRange(num? value, num minimum, num maximum) =>
    value != null && value.isFinite && value >= minimum && value <= maximum;
