import '../../../../core/result/result.dart';
import '../entities/health_date_range.dart';
import '../entities/health_metric.dart';
import '../entities/health_metric_type.dart';

abstract class HealthRepository {
  Future<Result<List<HealthMetric>>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  });

  Future<Result<List<HealthMetric>>> getAllMetrics({
    required HealthDateRange range,
  });
}