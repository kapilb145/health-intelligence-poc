import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/core/errors/failure.dart';
import 'package:health_intelligence_poc/core/result/result.dart' as result;
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_summary.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';
import 'package:health_intelligence_poc/features/health/domain/usecases/calculate_health_metrics_summary.dart';
import 'package:health_intelligence_poc/features/health/presentation/cubit/health_dashboard_cubit.dart';
import 'package:health_intelligence_poc/features/health/presentation/cubit/health_dashboard_state.dart';

void main() {
  group('HealthDashboardCubit', () {
    test('emits loading then loaded with summaries and trend points', () async {
      final useCase = _FakeCalculateHealthMetricsSummary();
      final cubit = HealthDashboardCubit(useCase);

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
      expect(loaded.trendPoints.length, 3);

      await cubit.close();
    });

    test('emits loading then error when use case fails', () async {
      final useCase = _FakeCalculateHealthMetricsSummary(
        failure: const UnexpectedFailure(message: 'Unable to load dashboard'),
      );
      final cubit = HealthDashboardCubit(useCase);

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
      final cubit = HealthDashboardCubit(useCase);

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
  });
}

class _FakeCalculateHealthMetricsSummary implements CalculateHealthMetricsSummary {
  _FakeCalculateHealthMetricsSummary({
    this.failure,
    this.zeroDataMetricTypes = const <HealthMetricType>{},
  });

  final Failure? failure;
  final Set<HealthMetricType> zeroDataMetricTypes;

  @override
  Future<result.Result<HealthMetricSummary>> call(
    CalculateHealthMetricsSummaryParams params,
  ) async {
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