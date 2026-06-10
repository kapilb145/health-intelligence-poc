import '../../../../core/result/result.dart';
import '../entities/health_date_range.dart';
import '../entities/health_metric.dart';
import '../entities/health_metric_type.dart';

/// Domain contract for retrieving health metrics across providers.
///
/// Implementations can use mock data, HealthKit, Health Connect,
/// or future integrations without changing domain/use-case code.
abstract class HealthRepository {
  Future<Result<List<HealthMetric>>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  });

  Future<Result<List<HealthMetric>>> getAllMetrics({
    required HealthDateRange range,
  });
}