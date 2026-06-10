import '../../domain/entities/health_metric_summary.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_trend_point.dart';

abstract class HealthDashboardState {
  const HealthDashboardState({
    required this.selectedTestDate,
  });

  final DateTime selectedTestDate;
}

class HealthDashboardInitial extends HealthDashboardState {
  const HealthDashboardInitial({
    required super.selectedTestDate,
  });
}

class HealthDashboardLoading extends HealthDashboardState {
  const HealthDashboardLoading({
    required super.selectedTestDate,
  });
}

class HealthDashboardLoaded extends HealthDashboardState {
  const HealthDashboardLoaded({
    required super.selectedTestDate,
    required this.metricSummaries,
    required this.trendPoints,
  });

  final Map<HealthMetricType, HealthMetricSummary> metricSummaries;
  final List<HealthTrendPoint> trendPoints;

  bool get isEmpty => metricSummaries.isEmpty;
}

class HealthDashboardError extends HealthDashboardState {
  const HealthDashboardError({
    required super.selectedTestDate,
    required this.message,
  });

  final String message;
}