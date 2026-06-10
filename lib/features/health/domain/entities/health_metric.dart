import 'health_data_provider.dart';
import 'health_metric_type.dart';
import 'health_unit.dart';

/// Provider-independent representation of a single health measurement.
///
/// Domain logic consumes this model without depending on HealthKit,
/// Health Connect, or mock/provider-specific payload formats.
class HealthMetric {
  const HealthMetric({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.source,
  });

  final String id;
  final HealthMetricType type;
  final double value;
  final HealthUnit unit;
  final DateTime recordedAt;
  final HealthDataProvider source;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is HealthMetric &&
        other.id == id &&
        other.type == type &&
        other.value == value &&
        other.unit == unit &&
        other.recordedAt == recordedAt &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(id, type, value, unit, recordedAt, source);
}