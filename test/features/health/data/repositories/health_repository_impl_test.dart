import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/core/exceptions/app_exception.dart';
import 'package:health_intelligence_poc/features/health/data/datasources/health_data_source.dart';
import 'package:health_intelligence_poc/features/health/data/models/health_metric_model.dart';
import 'package:health_intelligence_poc/features/health/data/repositories/health_repository_impl.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_data_provider.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_date_range.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';

void main() {
  group('HealthRepositoryImpl', () {
    test('returns Success with mapped entities when datasource succeeds', () async {
      final dataSource = _SuccessDataSource();
      final repository = HealthRepositoryImpl(dataSource);
      final range = HealthDateRange.custom(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );

      final result = await repository.getMetrics(
        type: HealthMetricType.steps,
        range: range,
      );

      expect(result.isSuccess, isTrue);
      result.when(
        onSuccess: (metrics) {
          expect(metrics.length, 1);
          expect(metrics.first.id, 'm-1');
          expect(metrics.first.type, HealthMetricType.steps);
          expect(metrics.first.value, 9000);
        },
        onFailure: (_) => fail('Expected success result'),
      );
    });

    test('returns Error when datasource throws', () async {
      final dataSource = _ThrowingDataSource();
      final repository = HealthRepositoryImpl(dataSource);
      final range = HealthDateRange.custom(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );

      final result = await repository.getMetrics(
        type: HealthMetricType.steps,
        range: range,
      );

      expect(result.isFailure, isTrue);
      result.when(
        onSuccess: (_) => fail('Expected failure result'),
        onFailure: (failure) {
          expect(failure.message, 'Datasource denied access');
        },
      );
    });
  });
}

class _SuccessDataSource implements HealthDataSource {
  @override
  Future<List<HealthMetricModel>> getAllMetrics({
    required HealthDateRange range,
  }) async {
    return [
      HealthMetricModel(
        id: 'm-1',
        type: HealthMetricType.steps,
        value: 9000,
        unit: HealthUnit.count,
        recordedAt: DateTime(2026, 6, 8, 8),
        source: HealthDataProvider.mock,
      ),
    ];
  }

  @override
  Future<List<HealthMetricModel>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  }) async {
    return [
      HealthMetricModel(
        id: 'm-1',
        type: type,
        value: 9000,
        unit: HealthUnit.count,
        recordedAt: DateTime(2026, 6, 8, 8),
        source: HealthDataProvider.mock,
      ),
    ];
  }
}

class _ThrowingDataSource implements HealthDataSource {
  @override
  Future<List<HealthMetricModel>> getAllMetrics({
    required HealthDateRange range,
  }) async {
    throw const PermissionDeniedException(message: 'Datasource denied access');
  }

  @override
  Future<List<HealthMetricModel>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  }) async {
    throw const PermissionDeniedException(message: 'Datasource denied access');
  }
}