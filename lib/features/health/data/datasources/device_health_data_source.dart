import 'dart:developer' as developer;
import 'dart:io';

import 'package:health/health.dart' as health;

import '../../../../core/exceptions/app_exception.dart';
import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric_type.dart';
import '../mappers/health_package_mapper.dart';
import '../models/health_metric_model.dart';
import 'health_data_source.dart';
import 'health_package_client.dart';

/// Native-provider datasource implementation for iOS/Android health stores.
///
/// Uses the health package adapter and mapper to convert provider data
/// into internal models while enforcing availability and permission checks.
class DeviceHealthDataSource implements HealthDataSource {
  DeviceHealthDataSource({
    required this._client,
    required this._mapper,
    bool Function()? platformSupported,
  }) :
        _platformSupported =
            platformSupported ?? _defaultPlatformSupported;

  final HealthPackageClient _client;
  final HealthPackageMapper _mapper;
  final bool Function() _platformSupported;
  bool _isReadAuthorizationGranted = false;

  static bool _defaultPlatformSupported() {
    return Platform.isIOS || Platform.isAndroid;
  }

  @override
  Future<List<HealthMetricModel>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  }) async {
    try {
      developer.log(
        'DeviceHealthDataSource.getMetrics type=${type.name} range=${range.startDate}..${range.endDate}',
        name: 'DeviceHealthDataSource',
      );
      _ensureSupportedPlatform();
      final externalType = _resolveExternalTypeForMetric(type);
      developer.log(
        'Resolved native type for ${type.name}: ${externalType.name} on ${Platform.operatingSystem}',
        name: 'DeviceHealthDataSource',
      );

      await _ensureAvailable();
      await _ensureReadPermissionsForSupportedTypes();

      final points = await _client.getHealthData(
        start: range.startDate,
        end: range.endDate,
        types: [externalType],
      );

      return points
          .map(_mapper.mapDataPoint)
          .where((metric) => metric.type == type)
          .toList(growable: false);
    } on AppException catch (error, stackTrace) {
      developer.log(
        'DeviceHealthDataSource AppException: ${error.message}',
        name: 'DeviceHealthDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'DeviceHealthDataSource unexpected error in getMetrics',
        name: 'DeviceHealthDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataUnavailableException(
        message: 'Unable to read health data from device provider: $error',
        details: error,
      );
    }
  }

  @override
  Future<List<HealthMetricModel>> getAllMetrics({
    required HealthDateRange range,
  }) async {
    try {
      developer.log(
        'DeviceHealthDataSource.getAllMetrics range=${range.startDate}..${range.endDate}',
        name: 'DeviceHealthDataSource',
      );
      _ensureSupportedPlatform();
      final types = _supportedExternalTypes();

      await _ensureAvailable();
      await _ensureReadPermissionsForSupportedTypes();

      final points = await _client.getHealthData(
        start: range.startDate,
        end: range.endDate,
        types: types,
      );

      final mapped = points.map(_mapper.mapDataPoint).toList(growable: false);
      return _deduplicateById(mapped);
    } on AppException catch (error, stackTrace) {
      developer.log(
        'DeviceHealthDataSource AppException: ${error.message}',
        name: 'DeviceHealthDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'DeviceHealthDataSource unexpected error in getAllMetrics',
        name: 'DeviceHealthDataSource',
        error: error,
        stackTrace: stackTrace,
      );
      throw DataUnavailableException(
        message: 'Unable to read health data from device provider: $error',
        details: error,
      );
    }
  }

  void _ensureSupportedPlatform() {
    if (_platformSupported()) {
      return;
    }

    throw const DataUnavailableException(
      message: 'Health data is only available on iOS and Android.',
    );
  }

  Future<void> _ensureAvailable() async {
    final isAvailable = await _client.isDataAvailable();
    developer.log(
      'Health availability result: $isAvailable',
      name: 'DeviceHealthDataSource',
    );
    if (!isAvailable) {
      throw const DataUnavailableException(
        message: 'Health data is unavailable on this device.',
      );
    }
  }

  Future<void> _ensureReadPermissions(List<health.HealthDataType> types) async {
    developer.log(
      'Requesting read permissions for: ${types.map((t) => t.name).join(', ')}',
      name: 'DeviceHealthDataSource',
    );
    final granted = await _client.requestReadAuthorization(types: types);
    developer.log(
      'Read permission grant result: $granted',
      name: 'DeviceHealthDataSource',
    );
    if (!granted) {
      throw PermissionDeniedException(
        message: 'Health data permission was denied for: ${types.map((t) => t.name).join(', ')}',
      );
    }
  }

  Future<void> _ensureReadPermissionsForSupportedTypes() async {
    if (_isReadAuthorizationGranted) {
      developer.log(
        'Skipping permission request; read authorization already granted for supported types.',
        name: 'DeviceHealthDataSource',
      );
      return;
    }

    final types = _supportedExternalTypes();
    developer.log(
      'Final native permission request types for ${Platform.operatingSystem}: ${types.map((t) => t.name).join(', ')}',
      name: 'DeviceHealthDataSource',
    );
    await _ensureReadPermissions(types);
    _isReadAuthorizationGranted = true;
  }

  List<HealthMetricModel> _deduplicateById(List<HealthMetricModel> metrics) {
    final seen = <String>{};
    final unique = <HealthMetricModel>[];
    for (final metric in metrics) {
      if (seen.add(metric.id)) {
        unique.add(metric);
      }
    }
    return unique;
  }

  List<health.HealthDataType> _supportedExternalTypes() {
    final resolved = [
      _resolveExternalTypeForMetric(HealthMetricType.steps),
      _resolveExternalTypeForMetric(HealthMetricType.restingHeartRate),
      _resolveExternalTypeForMetric(HealthMetricType.bloodPressureSystolic),
      _resolveExternalTypeForMetric(HealthMetricType.bloodPressureDiastolic),
      _resolveExternalTypeForMetric(HealthMetricType.weight),
      _resolveExternalTypeForMetric(HealthMetricType.sleepDuration),
    ];

    return resolved.toSet().toList(growable: false);
  }

  health.HealthDataType _resolveExternalTypeForMetric(HealthMetricType metricType) {
    final isIOS = Platform.isIOS;

    switch (metricType) {
      case HealthMetricType.steps:
        return _findTypeByCandidates(isIOS ? const ['STEPS'] : const ['STEPS']);
      case HealthMetricType.restingHeartRate:
        return _findTypeByCandidates(
          isIOS ? const ['HEART_RATE', 'RESTING_HEART_RATE'] : const ['RESTING_HEART_RATE', 'HEART_RATE'],
        );
      case HealthMetricType.bloodPressureSystolic:
        return _findTypeByCandidates(
          isIOS ? const ['BLOOD_PRESSURE_SYSTOLIC'] : const ['BLOOD_PRESSURE_SYSTOLIC'],
        );
      case HealthMetricType.bloodPressureDiastolic:
        return _findTypeByCandidates(
          isIOS ? const ['BLOOD_PRESSURE_DIASTOLIC'] : const ['BLOOD_PRESSURE_DIASTOLIC'],
        );
      case HealthMetricType.weight:
        return _findTypeByCandidates(
          isIOS ? const ['WEIGHT'] : const ['WEIGHT', 'BODY_MASS'],
        );
      case HealthMetricType.sleepDuration:
        return _findTypeByCandidates(
          isIOS ? const ['SLEEP_ASLEEP', 'SLEEP_IN_BED'] : const ['SLEEP_SESSION', 'SLEEP_ASLEEP'],
        );
      case HealthMetricType.bloodGlucose:
      case HealthMetricType.oxygenSaturation:
      case HealthMetricType.heartRateVariability:
      case HealthMetricType.caloriesBurned:
      case HealthMetricType.bodyTemperature:
        throw const ValidationException(
          message: 'Requested metric is not enabled in device data source.',
        );
    }
  }

  health.HealthDataType _findTypeByCandidates(List<String> candidates) {
    for (final candidate in candidates) {
      try {
        return health.HealthDataType.values.firstWhere(
          (type) => type.name.toUpperCase() == candidate,
        );
      } catch (_) {
        // Continue trying fallback enum names.
      }
    }

    throw DataUnavailableException(
      message: 'Required health type is not supported by the health package: '
          '${candidates.join(', ')}',
    );
  }
}