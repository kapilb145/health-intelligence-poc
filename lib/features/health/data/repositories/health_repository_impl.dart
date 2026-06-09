import '../../../../core/result/result.dart';
import '../../../../core/utils/exception_to_failure_mapper.dart';
import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_data_source.dart';

class HealthRepositoryImpl implements HealthRepository {
  const HealthRepositoryImpl(this._dataSource);

  final HealthDataSource _dataSource;

  @override
  Future<Result<List<HealthMetric>>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  }) async {
    try {
      final models = await _dataSource.getMetrics(
        type: type,
        range: range,
        
      );

      return Success(models.map((model) => model.toEntity()).toList());
    } catch (exception) {
      return Error(mapExceptionToFailure(exception));
    }
  }

  @override
  Future<Result<List<HealthMetric>>> getAllMetrics({
    required HealthDateRange range,
  }) async {
    try {
      final models = await _dataSource.getAllMetrics(range: range);
      return Success(models.map((model) => model.toEntity()).toList());
    } catch (exception) {
      return Error(mapExceptionToFailure(exception));
    }
  }
}