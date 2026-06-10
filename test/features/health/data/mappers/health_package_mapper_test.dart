import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart' as health;
import 'package:health_intelligence_poc/features/health/data/datasources/health_package_client.dart';
import 'package:health_intelligence_poc/features/health/data/mappers/health_package_mapper.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';

void main() {
  group('HealthPackageMapper', () {
    const mapper = HealthPackageMapper();

    test('maps steps data point into HealthMetricModel', () {
      final point = HealthPackageDataPoint(
        id: 'point-1',
        type: health.HealthDataType.STEPS,
        value: health.NumericHealthValue(numericValue: 8342),
        dateFrom: DateTime(2026, 6, 9, 8),
        dateTo: DateTime(2026, 6, 9, 8, 5),
      );

      final model = mapper.mapDataPoint(point);

      expect(model.id, 'point-1');
      expect(model.type, HealthMetricType.steps);
      expect(model.value, 8342);
      expect(model.unit, HealthUnit.count);
      expect(model.recordedAt, DateTime(2026, 6, 9, 8));
    });

    test('maps numericValue-based payload', () {
      final point = HealthPackageDataPoint(
        id: 'point-2',
        type: health.HealthDataType.WEIGHT,
        value: health.NumericHealthValue(numericValue: 72.4),
        dateFrom: DateTime(2026, 6, 9, 7),
        dateTo: DateTime(2026, 6, 9, 7, 2),
      );

      final model = mapper.mapDataPoint(point);

      expect(model.type, HealthMetricType.weight);
      expect(model.value, 72.4);
      expect(model.unit, HealthUnit.kilogram);
    });
  });
}