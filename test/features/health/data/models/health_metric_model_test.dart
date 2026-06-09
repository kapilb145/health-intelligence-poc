import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/features/health/data/models/health_metric_model.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_data_provider.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';

void main() {
  group('HealthMetricModel', () {
    test('maps entity to model and back to entity', () {
      final entity = HealthMetric(
        id: 'metric-1',
        type: HealthMetricType.steps,
        value: 8500,
        unit: HealthUnit.count,
        recordedAt: DateTime(2026, 6, 8, 8),
        source: HealthDataProvider.mock,
      );

      final model = HealthMetricModel.fromEntity(entity);
      final mappedEntity = model.toEntity();

      expect(mappedEntity, entity);
    });

    test('serializes and deserializes json', () {
      final model = HealthMetricModel(
        id: 'metric-2',
        type: HealthMetricType.weight,
        value: 72.5,
        unit: HealthUnit.kilogram,
        recordedAt: DateTime(2026, 6, 8, 7),
        source: HealthDataProvider.manual,
      );

      final json = model.toJson();
      final parsed = HealthMetricModel.fromJson(json);

      expect(parsed, model);
    });
  });
}