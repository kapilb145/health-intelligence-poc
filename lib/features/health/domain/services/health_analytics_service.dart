import '../entities/health_date_range.dart';
import '../entities/health_metric.dart';
import '../entities/health_metric_summary.dart';
import '../entities/health_metric_type.dart';
import '../entities/health_unit.dart';

/// Reusable calculation layer for health summaries and period-based averages.
///
/// This service is pure domain logic and remains independent from Flutter,
/// platform SDKs, and provider-specific APIs.
class HealthAnalyticsService {
  const HealthAnalyticsService();

  HealthMetricSummary summarize({
    required HealthMetricType metricType,
    required HealthDateRange dateRange,
    required List<HealthMetric> metrics,
  }) {
    final filtered = _filterByTypeAndRange(
      metrics: metrics,
      metricType: metricType,
      dateRange: dateRange,
    );

    if (filtered.isEmpty) {
      return HealthMetricSummary(
        metricType: metricType,
        average: 0,
        minimum: 0,
        maximum: 0,
        total: 0,
        dataPointCount: 0,
        unit: _defaultUnitFor(metricType),
        dateRange: dateRange,
      );
    }

    final total = calculateTotal(filtered);
    final count = calculateDataPointCount(filtered);

    return HealthMetricSummary(
      metricType: metricType,
      average: count == 0 ? 0 : total / count,
      minimum: calculateMinimum(filtered),
      maximum: calculateMaximum(filtered),
      total: total,
      dataPointCount: count,
      unit: filtered.first.unit,
      dateRange: dateRange,
    );
  }

  double calculateAverageForCustomPeriod({
    required HealthMetricType metricType,
    required DateTime start,
    required DateTime end,
    required List<HealthMetric> metrics,
  }) {
    final dateRange = HealthDateRange.custom(start, end);
    return summarize(
      metricType: metricType,
      dateRange: dateRange,
      metrics: metrics,
    ).average;
  }

  double calculate7DayAverage({
    required HealthMetricType metricType,
    required DateTime testDate,
    required List<HealthMetric> metrics,
  }) {
    return summarize(
      metricType: metricType,
      dateRange: HealthDateRange.last7Days(testDate),
      metrics: metrics,
    ).average;
  }

  double calculate30DayAverage({
    required HealthMetricType metricType,
    required DateTime testDate,
    required List<HealthMetric> metrics,
  }) {
    return summarize(
      metricType: metricType,
      dateRange: HealthDateRange.last30Days(testDate),
      metrics: metrics,
    ).average;
  }

  double calculateAverage(List<HealthMetric> metrics) {
    if (metrics.isEmpty) {
      return 0;
    }

    return calculateTotal(metrics) / metrics.length;
  }

  double calculateMinimum(List<HealthMetric> metrics) {
    if (metrics.isEmpty) {
      return 0;
    }

    var minValue = metrics.first.value;
    for (final metric in metrics.skip(1)) {
      if (metric.value < minValue) {
        minValue = metric.value;
      }
    }
    return minValue;
  }

  double calculateMaximum(List<HealthMetric> metrics) {
    if (metrics.isEmpty) {
      return 0;
    }

    var maxValue = metrics.first.value;
    for (final metric in metrics.skip(1)) {
      if (metric.value > maxValue) {
        maxValue = metric.value;
      }
    }
    return maxValue;
  }

  double calculateTotal(List<HealthMetric> metrics) {
    return metrics.fold<double>(0, (sum, metric) => sum + metric.value);
  }

  int calculateDataPointCount(List<HealthMetric> metrics) {
    return metrics.length;
  }

  List<HealthMetric> _filterByTypeAndRange({
    required List<HealthMetric> metrics,
    required HealthMetricType metricType,
    required HealthDateRange dateRange,
  }) {
    return metrics.where((metric) {
      final withinRange =
          !metric.recordedAt.isBefore(dateRange.startDate) &&
          !metric.recordedAt.isAfter(dateRange.endDate);

      return metric.type == metricType && withinRange;
    }).toList(growable: false);
  }

  HealthUnit _defaultUnitFor(HealthMetricType metricType) {
    switch (metricType) {
      case HealthMetricType.steps:
        return HealthUnit.count;
      case HealthMetricType.restingHeartRate:
        return HealthUnit.bpm;
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
        return HealthUnit.mmHg;
      case HealthMetricType.weight:
        return HealthUnit.kilogram;
      case HealthMetricType.sleepDuration:
        return HealthUnit.hours;
      case HealthMetricType.bloodGlucose:
        return HealthUnit.mgDl;
      case HealthMetricType.oxygenSaturation:
        return HealthUnit.percentage;
      case HealthMetricType.heartRateVariability:
        return HealthUnit.count;
      case HealthMetricType.caloriesBurned:
        return HealthUnit.kcal;
      case HealthMetricType.bodyTemperature:
        return HealthUnit.celsius;
    }
  }
}