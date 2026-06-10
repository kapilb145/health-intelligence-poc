import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart' as health;
import 'package:health_intelligence_poc/core/exceptions/app_exception.dart';
import 'package:health_intelligence_poc/features/health/data/datasources/device_health_data_source.dart';
import 'package:health_intelligence_poc/features/health/data/datasources/health_package_client.dart';
import 'package:health_intelligence_poc/features/health/data/mappers/health_package_mapper.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_date_range.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';

void main() {
  group('DeviceHealthDataSource', () {
    test('throws permission failure when authorization is denied', () async {
      final client = _FakeHealthPackageClient(
        available: true,
        permissionGranted: false,
      );
      final source = DeviceHealthDataSource(
        client: client,
        mapper: const HealthPackageMapper(),
        platformSupported: () => true,
      );

      final action = source.getMetrics(
        type: HealthMetricType.steps,
        range: HealthDateRange.custom(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 9),
        ),
      );

      await expectLater(action, throwsA(isA<PermissionDeniedException>()));
    });

    test('throws unavailable failure on unsupported platform', () async {
      final client = _FakeHealthPackageClient(
        available: true,
        permissionGranted: true,
      );
      final source = DeviceHealthDataSource(
        client: client,
        mapper: const HealthPackageMapper(),
        platformSupported: () => false,
      );

      final action = source.getAllMetrics(
        range: HealthDateRange.custom(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 9),
        ),
      );

      await expectLater(action, throwsA(isA<DataUnavailableException>()));
    });

    test('returns mapped metrics for successful request', () async {
      final client = _FakeHealthPackageClient(
        available: true,
        permissionGranted: true,
        dataPoints: [
          HealthPackageDataPoint(
            id: 'step-1',
            type: health.HealthDataType.STEPS,
            value: health.NumericHealthValue(numericValue: 9000),
            dateFrom: DateTime(2026, 6, 8, 8),
            dateTo: DateTime(2026, 6, 8, 8, 5),
          ),
        ],
      );
      final source = DeviceHealthDataSource(
        client: client,
        mapper: const HealthPackageMapper(),
        platformSupported: () => true,
      );

      final result = await source.getMetrics(
        type: HealthMetricType.steps,
        range: HealthDateRange.custom(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 9),
        ),
      );

      expect(result.length, 1);
      expect(result.first.id, 'step-1');
      expect(result.first.type, HealthMetricType.steps);
      expect(result.first.value, 9000);
    });

    test('requests read authorization only once per runtime', () async {
      final client = _FakeHealthPackageClient(
        available: true,
        permissionGranted: true,
      );
      final source = DeviceHealthDataSource(
        client: client,
        mapper: const HealthPackageMapper(),
        platformSupported: () => true,
      );

      await source.getMetrics(
        type: HealthMetricType.steps,
        range: HealthDateRange.custom(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 9),
        ),
      );

      await source.getAllMetrics(
        range: HealthDateRange.custom(
          DateTime(2026, 6, 1),
          DateTime(2026, 6, 9),
        ),
      );

      expect(client.requestReadAuthorizationCallCount, 1);
    });
  });
}

class _FakeHealthPackageClient implements HealthPackageClient {
  _FakeHealthPackageClient({
    required this.available,
    required this.permissionGranted,
    this.dataPoints = const [],
  });

  final bool available;
  final bool permissionGranted;
  final List<HealthPackageDataPoint> dataPoints;
  int requestReadAuthorizationCallCount = 0;

  @override
  Future<List<HealthPackageDataPoint>> getHealthData({
    required DateTime start,
    required DateTime end,
    required List<health.HealthDataType> types,
  }) async {
    return dataPoints;
  }

  @override
  Future<bool> isDataAvailable() async {
    return available;
  }

  @override
  Future<bool> requestReadAuthorization({
    required List<health.HealthDataType> types,
    bool forceRequest = false,
  }) async {
    requestReadAuthorizationCallCount++;
    return permissionGranted;
  }
}