import '../../../../core/result/result.dart' as result;
import '../../../../core/services/use_case.dart';
import '../entities/health_date_range.dart';
import '../entities/health_metric_summary.dart';
import '../entities/health_metric_type.dart';
import '../repositories/health_repository.dart';
import '../services/health_analytics_service.dart';

class CalculateHealthMetricsSummary
    implements
        UseCase<
          HealthMetricSummary,
          CalculateHealthMetricsSummaryParams
        > {
  CalculateHealthMetricsSummary(this._repository, this._analyticsService);

  final HealthRepository _repository;
  final HealthAnalyticsService _analyticsService;

  @override
  Future<result.Result<HealthMetricSummary>> call(
    CalculateHealthMetricsSummaryParams params,
  ) async {
    final metricsResult = await _repository.getMetrics(
      type: params.metricType,
      range: params.dateRange,
    );

    return metricsResult.when(
      onSuccess: (metrics) => result.Success(
        _analyticsService.summarize(
          metricType: params.metricType,
          dateRange: params.dateRange,
          metrics: metrics,
        ),
      ),
      onFailure: (failure) => result.Error<HealthMetricSummary>(failure),
    );
  }
}

class CalculateHealthMetricsSummaryParams {
  const CalculateHealthMetricsSummaryParams({
    required this.metricType,
    required this.dateRange,
  });

  final HealthMetricType metricType;
  final HealthDateRange dateRange;
}