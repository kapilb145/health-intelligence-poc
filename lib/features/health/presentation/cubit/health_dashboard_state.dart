import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric_summary.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_trend_point.dart';

enum HealthDashboardPeriod {
  last7Days,
  last30Days,
  custom,
}

abstract class HealthDashboardState {
  const HealthDashboardState({
    required this.selectedTestDate,
    required this.selectedPeriod,
    required this.selectedRange,
    this.customStartDate,
    this.customEndDate,
  });

  final DateTime selectedTestDate;
  final HealthDashboardPeriod selectedPeriod;
  final HealthDateRange selectedRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
}

class HealthDashboardInitial extends HealthDashboardState {
  const HealthDashboardInitial({
    required super.selectedTestDate,
    required super.selectedPeriod,
    required super.selectedRange,
    super.customStartDate,
    super.customEndDate,
  });
}

class HealthDashboardLoading extends HealthDashboardState {
  const HealthDashboardLoading({
    required super.selectedTestDate,
    required super.selectedPeriod,
    required super.selectedRange,
    super.customStartDate,
    super.customEndDate,
  });
}

class HealthDashboardLoaded extends HealthDashboardState {
  const HealthDashboardLoaded({
    required super.selectedTestDate,
    required super.selectedPeriod,
    required super.selectedRange,
    super.customStartDate,
    super.customEndDate,
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
    required super.selectedPeriod,
    required super.selectedRange,
    super.customStartDate,
    super.customEndDate,
    required this.message,
  });

  final String message;
}