import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_data_provider.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_date_range.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';
import 'package:health_intelligence_poc/features/health/domain/services/health_analytics_service.dart';

void main() {
  group('HealthAnalyticsService', () {
    const service = HealthAnalyticsService();

    test('calculates average for steps correctly', () {
      final testDate = DateTime(2026, 6, 10);
      final range = HealthDateRange.last7Days(testDate);

      final metrics = [
        _stepMetric(id: '1', value: 8000, recordedAt: DateTime(2026, 6, 3)),
        _stepMetric(id: '2', value: 9000, recordedAt: DateTime(2026, 6, 4)),
        _stepMetric(id: '3', value: 10000, recordedAt: DateTime(2026, 6, 9)),
      ];

      final summary = service.summarize(
        metricType: HealthMetricType.steps,
        dateRange: range,
        metrics: metrics,
      );

      expect(summary.average, 9000);
      expect(summary.minimum, 8000);
      expect(summary.maximum, 10000);
      expect(summary.total, 27000);
      expect(summary.dataPointCount, 3);
      expect(summary.unit, HealthUnit.count);
    });

    test('returns safe summary for empty data', () {
      final range = HealthDateRange.custom(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );

      final summary = service.summarize(
        metricType: HealthMetricType.steps,
        dateRange: range,
        metrics: const [],
      );

      expect(summary.average, 0);
      expect(summary.minimum, 0);
      expect(summary.maximum, 0);
      expect(summary.total, 0);
      expect(summary.dataPointCount, 0);
      expect(summary.unit, HealthUnit.count);
    });

    test('7 day average excludes test date and uses previous 7 days', () {
      final testDate = DateTime(2026, 6, 10);

      final metrics = [
        _stepMetric(id: '1', value: 7000, recordedAt: DateTime(2026, 6, 3)),
        _stepMetric(id: '2', value: 9000, recordedAt: DateTime(2026, 6, 9)),
        _stepMetric(id: '3', value: 20000, recordedAt: DateTime(2026, 6, 10)),
      ];

      final average = service.calculate7DayAverage(
        metricType: HealthMetricType.steps,
        testDate: testDate,
        metrics: metrics,
      );

      expect(average, 8000);
    });
  });
}

HealthMetric _stepMetric({
  required String id,
  required double value,
  required DateTime recordedAt,
}) {
  return HealthMetric(
    id: id,
    type: HealthMetricType.steps,
    value: value,
    unit: HealthUnit.count,
    recordedAt: recordedAt,
    source: HealthDataProvider.mock,
  );
}