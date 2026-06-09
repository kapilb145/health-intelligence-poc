import 'health_date_range.dart';
import 'health_metric_type.dart';
import 'health_unit.dart';

class HealthMetricSummary {
  const HealthMetricSummary({
    required this.metricType,
    required this.average,
    required this.minimum,
    required this.maximum,
    required this.total,
    required this.dataPointCount,
    required this.unit,
    required this.dateRange,
  });

  final HealthMetricType metricType;
  final double average;
  final double minimum;
  final double maximum;
  final double total;
  final int dataPointCount;
  final HealthUnit unit;
  final HealthDateRange dateRange;
}