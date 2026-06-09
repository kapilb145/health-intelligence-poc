import '../../domain/entities/health_data_provider.dart';
import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_unit.dart';
import '../models/health_metric_model.dart';
import 'health_data_source.dart';

class MockHealthDataSource implements HealthDataSource {
  MockHealthDataSource({
    DateTime? now,
    this.historyDays = 120,
  }) : _now = now ?? DateTime.now();

  final DateTime _now;
  final int historyDays;

  @override
  Future<List<HealthMetricModel>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  }) async {
    final all = _generateHistoricalMetrics();
    return all.where((metric) {
      return metric.type == type && _isWithinRange(metric.recordedAt, range);
    }).toList(growable: false);
  }

  @override
  Future<List<HealthMetricModel>> getAllMetrics({
    required HealthDateRange range,
  }) async {
    final all = _generateHistoricalMetrics();
    return all
        .where((metric) => _isWithinRange(metric.recordedAt, range))
        .toList(growable: false);
  }

  bool _isWithinRange(DateTime value, HealthDateRange range) {
    return !value.isBefore(range.startDate) && !value.isAfter(range.endDate);
  }

  List<HealthMetricModel> _generateHistoricalMetrics() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final output = <HealthMetricModel>[];

    for (var dayIndex = 0; dayIndex < historyDays; dayIndex++) {
      final day = today.subtract(Duration(days: dayIndex + 1));

      output.add(_metricForDay(
        day: day,
        type: HealthMetricType.steps,
        unit: HealthUnit.count,
        value: _rangeValue(dayIndex, min: 3000, max: 15000),
      ));

      output.add(_metricForDay(
        day: day,
        type: HealthMetricType.restingHeartRate,
        unit: HealthUnit.bpm,
        value: _rangeValue(dayIndex + 17, min: 55, max: 90),
      ));

      output.add(_metricForDay(
        day: day,
        type: HealthMetricType.bloodPressureSystolic,
        unit: HealthUnit.mmHg,
        value: _rangeValue(dayIndex + 31, min: 100, max: 135),
      ));

      output.add(_metricForDay(
        day: day,
        type: HealthMetricType.bloodPressureDiastolic,
        unit: HealthUnit.mmHg,
        value: _rangeValue(dayIndex + 47, min: 60, max: 90),
      ));

      output.add(_metricForDay(
        day: day,
        type: HealthMetricType.weight,
        unit: HealthUnit.kilogram,
        value: _rangeValue(dayIndex + 67, min: 50, max: 120),
      ));

      output.add(_metricForDay(
        day: day,
        type: HealthMetricType.sleepDuration,
        unit: HealthUnit.hours,
        value: _rangeValue(dayIndex + 83, min: 4, max: 10),
      ));
    }

    return output;
  }

  HealthMetricModel _metricForDay({
    required DateTime day,
    required HealthMetricType type,
    required HealthUnit unit,
    required double value,
  }) {
    final recordedAt = DateTime(day.year, day.month, day.day, 8, 0);
    final id = '${type.name}_${day.toIso8601String()}';
    return HealthMetricModel(
      id: id,
      type: type,
      value: value,
      unit: unit,
      recordedAt: recordedAt,
      source: HealthDataProvider.mock,
    );
  }

  double _rangeValue(
    int seed, {
    required int min,
    required int max,
  }) {
    final span = max - min;
    if (span <= 0) {
      return min.toDouble();
    }

    final normalized = ((seed * 37) % (span + 1)) + min;
    return normalized.toDouble();
  }
}