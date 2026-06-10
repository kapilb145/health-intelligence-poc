import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/core/errors/failure.dart';
import 'package:health_intelligence_poc/core/result/result.dart' as result;
import 'package:health_intelligence_poc/features/health/domain/entities/health_data_mode.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_date_range.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_summary.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';
import 'package:health_intelligence_poc/features/health/domain/services/health_data_mode_controller.dart';
import 'package:health_intelligence_poc/features/health/domain/usecases/calculate_health_metrics_summary.dart';
import 'package:health_intelligence_poc/features/health/presentation/cubit/health_dashboard_cubit.dart';
import 'package:health_intelligence_poc/features/health/presentation/cubit/health_dashboard_state.dart';

void main() {
  group('HealthDashboardCubit', () {
    test('emits loading then loaded with summaries and trend points', () async {
      final useCase = _FakeCalculateHealthMetricsSummary();
      final modeController = _FakeHealthDataModeController();
      final cubit = HealthDashboardCubit(useCase, modeController);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HealthDashboardLoading>(),
          isA<HealthDashboardLoaded>(),
        ]),
      );

      await cubit.loadDashboardData(testDate: DateTime(2026, 6, 10));
      await expectation;

      final loaded = cubit.state as HealthDashboardLoaded;
      expect(loaded.metricSummaries.length, 4);
      expect(loaded.trendPoints.length, 7);
      expect(loaded.trendPoints.first.date, DateTime(2026, 6, 3));
      expect(loaded.trendPoints.last.date, DateTime(2026, 6, 9));
      expect(loaded.selectedPeriod, HealthDashboardPeriod.last7Days);
      expect(loaded.selectedDataMode, HealthDataMode.mock);
      expect(loaded.selectedRange, HealthDateRange.last7Days(DateTime(2026, 6, 10)));

      await cubit.close();
    });

    test('emits loading then error when use case fails', () async {
      final useCase = _FakeCalculateHealthMetricsSummary(
        failure: const UnexpectedFailure(message: 'Unable to load dashboard'),
      );
      final modeController = _FakeHealthDataModeController();
      final cubit = HealthDashboardCubit(useCase, modeController);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HealthDashboardLoading>(),
          isA<HealthDashboardError>(),
        ]),
      );

      await cubit.loadDashboardData(testDate: DateTime(2026, 6, 10));
      await expectation;
      expect((cubit.state as HealthDashboardError).message, contains('Unable to load dashboard'));

      await cubit.close();
    });

    test('omits summaries that have zero data points', () async {
      final useCase = _FakeCalculateHealthMetricsSummary(
        zeroDataMetricTypes: {
          HealthMetricType.restingHeartRate,
          HealthMetricType.sleepDuration,
          HealthMetricType.weight,
        },
      );
      final modeController = _FakeHealthDataModeController();
      final cubit = HealthDashboardCubit(useCase, modeController);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<HealthDashboardLoading>(),
          isA<HealthDashboardLoaded>(),
        ]),
      );

      await cubit.loadDashboardData(testDate: DateTime(2026, 6, 10));
      await expectation;

      final loaded = cubit.state as HealthDashboardLoaded;
      expect(loaded.metricSummaries.keys, {HealthMetricType.steps});

      await cubit.close();
    });

    test('uses last30Days range when last30Days period is selected', () async {
      final useCase = _FakeCalculateHealthMetricsSummary();
      final modeController = _FakeHealthDataModeController();
      final cubit = HealthDashboardCubit(useCase, modeController);

      await cubit.loadDashboardData(
        testDate: DateTime(2026, 6, 10),
        period: HealthDashboardPeriod.last30Days,
      );

      final loaded = cubit.state as HealthDashboardLoaded;
      expect(loaded.selectedPeriod, HealthDashboardPeriod.last30Days);
      expect(loaded.selectedRange, HealthDateRange.last30Days(DateTime(2026, 6, 10)));
      expect(loaded.trendPoints.length, 30);
      expect(loaded.trendPoints.first.date, DateTime(2026, 5, 11));
      expect(loaded.trendPoints.last.date, DateTime(2026, 6, 9));

      await cubit.close();
    });

    test('uses custom range when custom period is selected', () async {
      final useCase = _FakeCalculateHealthMetricsSummary();
      final modeController = _FakeHealthDataModeController();
      final cubit = HealthDashboardCubit(useCase, modeController);

      await cubit.loadDashboardData(
        period: HealthDashboardPeriod.custom,
        customStartDate: DateTime(2026, 1, 1),
        customEndDate: DateTime(2026, 1, 7),
      );

      final loaded = cubit.state as HealthDashboardLoaded;
      expect(loaded.selectedPeriod, HealthDashboardPeriod.custom);
      expect(
        loaded.selectedRange,
        HealthDateRange.custom(DateTime(2026, 1, 1), DateTime(2026, 1, 7)),
      );
      expect(loaded.trendPoints.length, 7);
      expect(loaded.trendPoints.first.date, DateTime(2026, 1, 1));
      expect(loaded.trendPoints.last.date, DateTime(2026, 1, 7));

      await cubit.close();
    });

    test('changeDataSource updates mode and reloads dashboard data', () async {
      final useCase = _FakeCalculateHealthMetricsSummary();
      final modeController = _FakeHealthDataModeController();
      final cubit = HealthDashboardCubit(useCase, modeController);

      await cubit.loadDashboardData(testDate: DateTime(2026, 6, 10));
      final callCountBefore = useCase.callCount;

      await cubit.changeDataSource(HealthDataMode.device);

      expect(modeController.currentMode, HealthDataMode.device);
      expect(cubit.state, isA<HealthDashboardLoaded>());
      final loaded = cubit.state as HealthDashboardLoaded;
      expect(loaded.selectedDataMode, HealthDataMode.device);
      expect(useCase.callCount, greaterThan(callCountBefore));

      await cubit.close();
    });
  });
}

class _FakeCalculateHealthMetricsSummary implements CalculateHealthMetricsSummary {
  _FakeCalculateHealthMetricsSummary({
    this.failure,
    this.zeroDataMetricTypes = const <HealthMetricType>{},
  });

  final Failure? failure;
  final Set<HealthMetricType> zeroDataMetricTypes;
  int callCount = 0;

  @override
  Future<result.Result<HealthMetricSummary>> call(
    CalculateHealthMetricsSummaryParams params,
  ) async {
    callCount += 1;
    if (failure != null) {
      return result.Error(failure!);
    }

    final average = switch (params.metricType) {
      HealthMetricType.steps => 9200.0,
      HealthMetricType.restingHeartRate => 66.0,
      HealthMetricType.sleepDuration => 7.2,
      HealthMetricType.weight => 73.4,
      _ => 0.0,
    };

    final unit = switch (params.metricType) {
      HealthMetricType.steps => HealthUnit.count,
      HealthMetricType.restingHeartRate => HealthUnit.bpm,
      HealthMetricType.sleepDuration => HealthUnit.hours,
      HealthMetricType.weight => HealthUnit.kilogram,
      _ => HealthUnit.count,
    };

    final isZeroData = zeroDataMetricTypes.contains(params.metricType);

    return result.Success(
      HealthMetricSummary(
        metricType: params.metricType,
        average: isZeroData ? 0 : average,
        minimum: isZeroData ? 0 : average - 1,
        maximum: isZeroData ? 0 : average + 1,
        total: isZeroData ? 0 : average * 7,
        dataPointCount: isZeroData ? 0 : 7,
        unit: unit,
        dateRange: params.dateRange,
      ),
    );
  }
}

class _FakeHealthDataModeController implements HealthDataModeController {
  HealthDataMode _mode = HealthDataMode.mock;

  @override
  HealthDataMode get currentMode => _mode;

  @override
  Future<void> setMode(HealthDataMode mode) async {
    _mode = mode;
  }
}