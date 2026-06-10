import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric_summary.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_trend_point.dart';
import '../../domain/usecases/calculate_health_metrics_summary.dart';
import 'health_dashboard_state.dart';

class HealthDashboardCubit extends Cubit<HealthDashboardState> {
  HealthDashboardCubit(this._calculateHealthMetricsSummary)
      : super(
          HealthDashboardInitial(
            selectedTestDate: DateTime.now(),
            selectedPeriod: HealthDashboardPeriod.last7Days,
            selectedRange: HealthDateRange.last7Days(DateTime.now()),
          ),
        ) {
      _trace('HealthDashboardCubit created.');
  }

  final CalculateHealthMetricsSummary _calculateHealthMetricsSummary;

  static const List<HealthMetricType> _dashboardMetrics = [
    HealthMetricType.steps,
    HealthMetricType.restingHeartRate,
    HealthMetricType.sleepDuration,
    HealthMetricType.weight,
  ];

  Future<void> loadDashboardData({
    DateTime? testDate,
    HealthDashboardPeriod? period,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) async {
    final selectedDate = _normalizeDate(testDate ?? state.selectedTestDate);
    final selectedPeriod = period ?? state.selectedPeriod;
    final selectedCustomStart = _normalizeNullableDate(customStartDate ?? state.customStartDate);
    final selectedCustomEnd = _normalizeNullableDate(customEndDate ?? state.customEndDate);
    final selectedRange = _resolveSelectedRange(
      selectedDate: selectedDate,
      period: selectedPeriod,
      customStartDate: selectedCustomStart,
      customEndDate: selectedCustomEnd,
    );

    _trace('loadDashboardData start for $selectedDate');
    emit(
      HealthDashboardLoading(
        selectedTestDate: selectedDate,
        selectedPeriod: selectedPeriod,
        selectedRange: selectedRange,
        customStartDate: selectedCustomStart,
        customEndDate: selectedCustomEnd,
      ),
    );

    try {
      final range = selectedRange;
      _trace('Requesting summaries for metrics: ${_dashboardMetrics.map((e) => e.name).join(', ')}');
      final summaryResults = await Future.wait(
        _dashboardMetrics.map(
          (metric) => _loadSummarySafely(
            metricType: metric,
            range: range,
          ),
        ),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Timed out while loading dashboard summaries.'),
      );

      final summaryMap = <HealthMetricType, HealthMetricSummary>{
        for (final summary in summaryResults.whereType<HealthMetricSummary>())
          summary.metricType: summary,
      };

      _trace('Summary results received: ${summaryMap.keys.map((e) => e.name).join(', ')}');

      final trendPoints = await _loadTrendPoints(
        selectedDate: selectedDate,
        period: selectedPeriod,
        customStartDate: selectedCustomStart,
        customEndDate: selectedCustomEnd,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Timed out while loading trend points.'),
      );
      _trace('Trend points loaded: ${trendPoints.length}');

      emit(
        HealthDashboardLoaded(
          selectedTestDate: selectedDate,
          selectedPeriod: selectedPeriod,
          selectedRange: selectedRange,
          customStartDate: selectedCustomStart,
          customEndDate: selectedCustomEnd,
          metricSummaries: summaryMap,
          trendPoints: trendPoints,
        ),
      );
      _trace('HealthDashboardLoaded emitted.');
    } catch (error, stackTrace) {
      _trace('loadDashboardData failed: $error');
      developer.log('loadDashboardData failed', name: 'HealthDashboardCubit', error: error, stackTrace: stackTrace);
      emit(
        HealthDashboardError(
          selectedTestDate: selectedDate,
          selectedPeriod: selectedPeriod,
          selectedRange: selectedRange,
          customStartDate: selectedCustomStart,
          customEndDate: selectedCustomEnd,
          message: error.toString(),
        ),
      );
    }
  }

  Future<HealthMetricSummary?> _loadSummarySafely({
    required HealthMetricType metricType,
    required HealthDateRange range,
  }) async {
    try {
      final summary = await _loadSummary(metricType: metricType, range: range);
      if (summary.dataPointCount == 0) {
        _trace('Skipping metric ${metricType.name} because no data points were returned.');
        return null;
      }
      return summary;
    } catch (error) {
      _trace('Skipping metric ${metricType.name} due to error: $error');
      return null;
    }
  }

  Future<HealthMetricSummary> _loadSummary({
    required HealthMetricType metricType,
    required HealthDateRange range,
  }) async {
    _trace('Calling use case for metric=${metricType.name}, range=${range.startDate}..${range.endDate}');
    final summaryResult = await _calculateHealthMetricsSummary(
      CalculateHealthMetricsSummaryParams(
        metricType: metricType,
        dateRange: range,
      ),
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('Use case timed out for ${metricType.name}.'),
    );
    _trace('Use case returned for ${metricType.name}');

    return summaryResult.when(
      onSuccess: (summary) => summary,
      onFailure: (failure) => throw Exception('Metric ${metricType.name}: ${failure.message}'),
    );
  }

  Future<List<HealthTrendPoint>> _loadTrendPoints({
    required DateTime selectedDate,
    required HealthDashboardPeriod period,
    required DateTime? customStartDate,
    required DateTime? customEndDate,
  }) async {
    final checkpoints = [
      selectedDate.subtract(const Duration(days: 9)),
      selectedDate.subtract(const Duration(days: 5)),
      selectedDate,
    ];

    final points = <HealthTrendPoint>[];

    for (final checkpoint in checkpoints) {
      _trace('Loading trend checkpoint: $checkpoint');
      final summaryResult = await _calculateHealthMetricsSummary(
        CalculateHealthMetricsSummaryParams(
          metricType: HealthMetricType.steps,
          dateRange: _resolveSelectedRange(
            selectedDate: checkpoint,
            period: period,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
          ),
        ),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Trend use case timed out for $checkpoint.'),
      );

      summaryResult.when(
        onSuccess: (summary) {
          points.add(
            HealthTrendPoint(
              date: _normalizeDate(checkpoint),
              value: summary.average,
              metricType: summary.metricType,
              unit: summary.unit,
            ),
          );
        },
        onFailure: (failure) => throw Exception(failure.message),
      );
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _normalizeNullableDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return _normalizeDate(value);
  }

  HealthDateRange _resolveSelectedRange({
    required DateTime selectedDate,
    required HealthDashboardPeriod period,
    required DateTime? customStartDate,
    required DateTime? customEndDate,
  }) {
    switch (period) {
      case HealthDashboardPeriod.last7Days:
        return HealthDateRange.last7Days(selectedDate);
      case HealthDashboardPeriod.last30Days:
        return HealthDateRange.last30Days(selectedDate);
      case HealthDashboardPeriod.custom:
        final start = customStartDate;
        final end = customEndDate;
        if (start == null || end == null) {
          return HealthDateRange.last7Days(selectedDate);
        }
        if (end.isBefore(start)) {
          return HealthDateRange.custom(end, start);
        }
        return HealthDateRange.custom(start, end);
    }
  }

  void _trace(String message) {
    developer.log(message, name: 'HealthDashboardCubit');
    // ignore: avoid_print
    print('[HealthDashboardCubit] $message');
  }
}