import 'health_metric_type.dart';
import 'health_unit.dart';

class HealthTrendPoint {
  const HealthTrendPoint({
    required this.date,
    required this.value,
    required this.metricType,
    required this.unit,
  });

  final DateTime date;
  final double value;
  final HealthMetricType metricType;
  final HealthUnit unit;
}