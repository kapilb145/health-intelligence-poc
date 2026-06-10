import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart' as health;
import 'package:health_intelligence_poc/features/health/data/datasources/health_package_client.dart';

void main() {
  group('HealthPackageClientImpl', () {
    test('skips requestAuthorization when SDK already reports read permissions', () async {
      final sdk = _FakeHealthSdk(
        hasPermissionsResult: true,
        requestAuthorizationResult: true,
      );
      final client = HealthPackageClientImpl(sdk: sdk);

      final granted = await client.requestReadAuthorization(
        types: [health.HealthDataType.STEPS],
      );

      expect(granted, isTrue);
      expect(sdk.hasPermissionsCalls, 1);
      expect(sdk.requestAuthorizationCalls, 0);
    });

    test('uses runtime authorization cache after first granted request', () async {
      final sdk = _FakeHealthSdk(
        hasPermissionsResult: false,
        requestAuthorizationResult: true,
      );
      final client = HealthPackageClientImpl(sdk: sdk);

      final firstGranted = await client.requestReadAuthorization(
        types: [health.HealthDataType.STEPS],
      );
      final secondGranted = await client.requestReadAuthorization(
        types: [health.HealthDataType.STEPS],
      );

      expect(firstGranted, isTrue);
      expect(secondGranted, isTrue);
      expect(sdk.hasPermissionsCalls, 1);
      expect(sdk.requestAuthorizationCalls, 1);
    });

    test('reuses in-flight authorization request for concurrent callers', () async {
      final sdk = _FakeHealthSdk(
        hasPermissionsResult: false,
        requestAuthorizationResult: true,
        requestAuthorizationDelay: const Duration(milliseconds: 50),
      );
      final client = HealthPackageClientImpl(sdk: sdk);

      final results = await Future.wait([
        client.requestReadAuthorization(types: [health.HealthDataType.STEPS]),
        client.requestReadAuthorization(types: [health.HealthDataType.STEPS]),
      ]);

      expect(results, [true, true]);
      expect(sdk.requestAuthorizationCalls, 1);
    });
  });
}

class _FakeHealthSdk extends health.Health {
  _FakeHealthSdk({
    required this.hasPermissionsResult,
    required this.requestAuthorizationResult,
    this.requestAuthorizationDelay = Duration.zero,
  });

  final bool? hasPermissionsResult;
  final bool requestAuthorizationResult;
  final Duration requestAuthorizationDelay;

  int hasPermissionsCalls = 0;
  int requestAuthorizationCalls = 0;
  int configureCalls = 0;

  @override
  Future<void> configure() async {
    configureCalls++;
  }

  @override
  Future<bool?> hasPermissions(
    List<health.HealthDataType> types, {
    List<health.HealthDataAccess>? permissions,
  }) async {
    hasPermissionsCalls++;
    return hasPermissionsResult;
  }

  @override
  Future<bool> requestAuthorization(
    List<health.HealthDataType> types, {
    List<health.HealthDataAccess>? permissions,
  }) async {
    requestAuthorizationCalls++;
    if (requestAuthorizationDelay > Duration.zero) {
      await Future<void>.delayed(requestAuthorizationDelay);
    }
    return requestAuthorizationResult;
  }
}
