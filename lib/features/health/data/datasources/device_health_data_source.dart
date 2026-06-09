import 'dart:io';

import 'package:health/health.dart' as health;

import '../../../../core/exceptions/app_exception.dart';
import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric_type.dart';
import '../mappers/health_package_mapper.dart';
import '../models/health_metric_model.dart';
import 'health_data_source.dart';
import 'health_package_client.dart';

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

    static bool _defaultPlatformSupported() {
    return Platform.isIOS || Platform.isAndroid;
  }

  @override
  Future<List<HealthMetricModel>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  }) async {
    try {
      _ensureSupportedPlatform();
      final externalType = _resolveExternalTypeForMetric(type);

      await _ensureAvailable();
      await _ensureReadPermissions([externalType]);

      final points = await _client.getHealthData(
        start: range.startDate,
        end: range.endDate,
        types: [externalType],
      );

      return points
          .map(_mapper.mapDataPoint)
          .where((metric) => metric.type == type)
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DataUnavailableException(
        message: 'Unable to read health data from device provider.',
        details: error,
      );
    }
  }

  @override
  Future<List<HealthMetricModel>> getAllMetrics({
    required HealthDateRange range,
  }) async {
    try {
      _ensureSupportedPlatform();
      final types = _supportedExternalTypes();

      await _ensureAvailable();
      await _ensureReadPermissions(types);

      final points = await _client.getHealthData(
        start: range.startDate,
        end: range.endDate,
        types: types,
      );

      final mapped = points.map(_mapper.mapDataPoint).toList(growable: false);
      return _deduplicateById(mapped);
    } on AppException {
      rethrow;
    } catch (error) {
      throw DataUnavailableException(
        message: 'Unable to read health data from device provider.',
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
    if (!isAvailable) {
      throw const DataUnavailableException(
        message: 'Health data is unavailable on this device.',
      );
    }
  }

  Future<void> _ensureReadPermissions(List<health.HealthDataType> types) async {
    final granted = await _client.requestReadAuthorization(types: types);
    if (!granted) {
      throw const PermissionDeniedException(
        message: 'Health data permission was denied.',
      );
    }
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
    return [
      _resolveExternalTypeForMetric(HealthMetricType.steps),
      _resolveExternalTypeForMetric(HealthMetricType.restingHeartRate),
      _resolveExternalTypeForMetric(HealthMetricType.bloodPressureSystolic),
      _resolveExternalTypeForMetric(HealthMetricType.bloodPressureDiastolic),
      _resolveExternalTypeForMetric(HealthMetricType.weight),
      _resolveExternalTypeForMetric(HealthMetricType.sleepDuration),
    ];
  }

  health.HealthDataType _resolveExternalTypeForMetric(HealthMetricType metricType) {
    switch (metricType) {
      case HealthMetricType.steps:
        return _findTypeByCandidates(const ['STEPS']);
      case HealthMetricType.restingHeartRate:
        return _findTypeByCandidates(const ['RESTING_HEART_RATE', 'HEART_RATE']);
      case HealthMetricType.bloodPressureSystolic:
        return _findTypeByCandidates(const ['BLOOD_PRESSURE_SYSTOLIC']);
      case HealthMetricType.bloodPressureDiastolic:
        return _findTypeByCandidates(const ['BLOOD_PRESSURE_DIASTOLIC']);
      case HealthMetricType.weight:
        return _findTypeByCandidates(const ['WEIGHT', 'BODY_MASS']);
      case HealthMetricType.sleepDuration:
        return _findTypeByCandidates(const ['SLEEP_ASLEEP', 'SLEEP_SESSION']);
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