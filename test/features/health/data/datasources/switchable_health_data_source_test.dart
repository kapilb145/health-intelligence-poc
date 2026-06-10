import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/features/health/data/datasources/health_data_source.dart';
import 'package:health_intelligence_poc/features/health/data/datasources/switchable_health_data_source.dart';
import 'package:health_intelligence_poc/features/health/data/models/health_metric_model.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_data_mode.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_data_provider.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_date_range.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';

void main() {
  group('SwitchableHealthDataSource', () {
    test('delegates to mock source by default', () async {
      final source = SwitchableHealthDataSource(
        mockDataSource: _NamedDataSource('mock-id'),
        deviceDataSource: _NamedDataSource('device-id'),
      );

      final result = await source.getMetrics(
        type: HealthMetricType.steps,
        range: HealthDateRange.custom(DateTime(2026, 6, 1), DateTime(2026, 6, 2)),
      );

      expect(result.single.id, 'mock-id');
      expect(source.currentMode, HealthDataMode.mock);
    });

    test('switches to device source at runtime', () async {
      final source = SwitchableHealthDataSource(
        mockDataSource: _NamedDataSource('mock-id'),
        deviceDataSource: _NamedDataSource('device-id'),
      );

      await source.setMode(HealthDataMode.device);
      final result = await source.getMetrics(
        type: HealthMetricType.steps,
        range: HealthDateRange.custom(DateTime(2026, 6, 1), DateTime(2026, 6, 2)),
      );

      expect(result.single.id, 'device-id');
      expect(source.currentMode, HealthDataMode.device);
    });
  });
}

class _NamedDataSource implements HealthDataSource {
  _NamedDataSource(this.id);

  final String id;

  @override
  Future<List<HealthMetricModel>> getAllMetrics({required HealthDateRange range}) async {
    return [
      HealthMetricModel(
        id: id,
        type: HealthMetricType.steps,
        value: 8000,
        unit: HealthUnit.count,
        recordedAt: DateTime(2026, 6, 1),
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
        id: id,
        type: type,
        value: 8000,
        unit: HealthUnit.count,
        recordedAt: DateTime(2026, 6, 1),
        source: HealthDataProvider.mock,
      ),
    ];
  }
}
