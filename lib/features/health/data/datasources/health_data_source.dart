import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric_type.dart';
import '../models/health_metric_model.dart';

abstract class HealthDataSource {
  Future<List<HealthMetricModel>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  });

  Future<List<HealthMetricModel>> getAllMetrics({
    required HealthDateRange range,
  });
}