import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:health/health.dart' as health;
import 'package:shared_preferences/shared_preferences.dart';

class HealthPackageDataPoint {
  const HealthPackageDataPoint({
    required this.id,
    required this.type,
    required this.value,
    required this.dateFrom,
    required this.dateTo,
  });

  final String id;
  final health.HealthDataType type;
  final health.HealthValue value;
  final DateTime dateFrom;
  final DateTime dateTo;
}

abstract class HealthPackageClient {
  Future<bool> isDataAvailable();

  Future<bool> requestReadAuthorization({
    required List<health.HealthDataType> types,
    bool forceRequest = false,
  });

  Future<List<HealthPackageDataPoint>> getHealthData({
    required DateTime start,
    required DateTime end,
    required List<health.HealthDataType> types,
  });
}

class HealthPackageClientImpl implements HealthPackageClient {
  HealthPackageClientImpl({health.Health? sdk}) : _sdk = sdk ?? health.Health();

  static const Duration _externalCallTimeout = Duration(seconds: 20);
  static const String _healthPermissionRequestedKey = 'health_permission_requested';

  final health.Health _sdk;
  bool _isConfigured = false;
  bool _isReadAuthorizationGranted = false;
  Future<bool>? _authorizationInFlight;

  @override
  Future<bool> isDataAvailable() async {
    final configured = await _ensureConfigured();
    if (!configured) {
      _trace('Health availability check: SDK configure failed.');
      return false;
    }

    if (Platform.isIOS) {
      _trace('Health availability check: iOS assumed available after configure().');
      return true;
    }

    if (!Platform.isAndroid) {
      _trace('Health availability check: unsupported platform ${Platform.operatingSystem}.');
      return false;
    }

    try {
      final available = await _sdk.isHealthConnectAvailable().timeout(
        _externalCallTimeout,
        onTimeout: () => throw TimeoutException('Health Connect availability check timed out.'),
      );
      _trace('Health Connect availability: $available');
      return available;
    } on PlatformException catch (error, stackTrace) {
      _trace('Health availability platform exception: ${error.code} ${error.message ?? ''}');
      developer.log(
        'Health availability platform exception',
        name: 'HealthPackageClient',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> requestReadAuthorization({
    required List<health.HealthDataType> types,
    bool forceRequest = false,
  }) async {
    if (_authorizationInFlight != null) {
      _trace('Authorization already in progress; awaiting existing request.');
      return _authorizationInFlight!;
    }

    _authorizationInFlight = _requestReadAuthorizationInternal(
      types: types,
      forceRequest: forceRequest,
    );

    try {
      return await _authorizationInFlight!;
    } finally {
      _authorizationInFlight = null;
    }
  }

  Future<bool> _requestReadAuthorizationInternal({
    required List<health.HealthDataType> types,
    required bool forceRequest,
  }) async {

    if (_isReadAuthorizationGranted) {
      _trace('Skipping permission request; runtime read authorization cache is true.');
      return true;
    }

    final configured = await _ensureConfigured();
    if (!configured) {
      return false;
    }

    final resolvedTypes = _resolveSupportedTypesForCurrentPlatform(
      types: types,
      purpose: 'authorization',
    );
    if (resolvedTypes.isEmpty) {
      _trace('Skipping authorization request because no supported types remain.');
      return false;
    }

    final hasReadPermission = await _hasReadPermissions(resolvedTypes);
    if (hasReadPermission) {
      _isReadAuthorizationGranted = true;
      _trace('Skipping permission request; Health SDK reports existing read permissions.');
      return true;
    }

    if (Platform.isIOS && !forceRequest) {
      final alreadyRequested = await _wasPermissionRequestedBefore();
      if (alreadyRequested) {
        _trace('Skipping iOS permission request; permission decision was already requested in a prior launch.');
        return true;
      }
    }

    _trace('Requesting Health permissions for types: ${resolvedTypes.map((t) => t.name).join(', ')}');
    final permissions = List<health.HealthDataAccess>.filled(
      resolvedTypes.length,
      health.HealthDataAccess.READ,
      growable: false,
    );

    try {
      final granted = await _sdk.requestAuthorization(
        resolvedTypes,
        permissions: permissions,
      ).timeout(
        _externalCallTimeout,
        onTimeout: () => throw TimeoutException('Health permission request timed out.'),
      );
      await _markPermissionRequested();
      _trace('Health permission request result: $granted');
      if (granted) {
        _isReadAuthorizationGranted = true;
      }
      return granted;
    } on PlatformException catch (error, stackTrace) {
      _trace('Health permission platform exception: ${error.code} ${error.message ?? ''}');
      developer.log(
        'Health permission platform exception',
        name: 'HealthPackageClient',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> _hasReadPermissions(List<health.HealthDataType> types) async {
    final permissions = List<health.HealthDataAccess>.filled(
      types.length,
      health.HealthDataAccess.READ,
      growable: false,
    );

    try {
      final hasPermissions = await _sdk
          .hasPermissions(types, permissions: permissions)
          .timeout(
            _externalCallTimeout,
            onTimeout: () => throw TimeoutException('Health permission status check timed out.'),
          );
      _trace('Health permission status check result: $hasPermissions');
      return hasPermissions == true;
    } on PlatformException catch (error, stackTrace) {
      _trace('Health permission status platform exception: ${error.code} ${error.message ?? ''}');
      developer.log(
        'Health permission status platform exception',
        name: 'HealthPackageClient',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } on TimeoutException catch (error, stackTrace) {
      _trace(error.message ?? 'Health permission status check timed out.');
      developer.log(
        'Health permission status timeout',
        name: 'HealthPackageClient',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> _wasPermissionRequestedBefore() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      return preferences.getBool(_healthPermissionRequestedKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markPermissionRequested() async {
    if (!Platform.isIOS) {
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_healthPermissionRequestedKey, true);
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  @override
  Future<List<HealthPackageDataPoint>> getHealthData({
    required DateTime start,
    required DateTime end,
    required List<health.HealthDataType> types,
  }) async {
    final configured = await _ensureConfigured();
    if (!configured) {
      return const [];
    }
    final resolvedTypes = _resolveSupportedTypesForCurrentPlatform(
      types: types,
      purpose: 'read',
    );
    if (resolvedTypes.isEmpty) {
      _trace('Skipping health read because no supported types remain.');
      return const [];
    }

    _trace('Fetching health data from $start to $end for ${resolvedTypes.map((t) => t.name).join(', ')}');
    late final List<health.HealthDataPoint> points;
    try {
      points = await _sdk.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: resolvedTypes,
      ).timeout(
        _externalCallTimeout,
        onTimeout: () => throw TimeoutException('Health data read timed out.'),
      );
    } on PlatformException catch (error, stackTrace) {
      _trace('Health read platform exception: ${error.code} ${error.message ?? ''}');
      developer.log(
        'Health read platform exception',
        name: 'HealthPackageClient',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }

    _trace('Fetched health data points: ${points.length}');

    return points.map((point) {
      final id = _readId(point);
      return HealthPackageDataPoint(
        id: id,
        type: point.type,
        value: point.value,
        dateFrom: point.dateFrom,
        dateTo: point.dateTo,
      );
    }).toList(growable: false);
  }

  String _readId(health.HealthDataPoint point) {
    final json = point.toJson();
    final rawId = json['uuid'] ?? json['id'];
    if (rawId is String && rawId.isNotEmpty) {
      return rawId;
    }

    return '${point.type.name}_${point.dateFrom.toIso8601String()}';
  }

  Future<bool> _ensureConfigured() async {
    if (_isConfigured) {
      return true;
    }

    _trace('Configuring Health SDK.');
    try {
      await _sdk.configure();
      _isConfigured = true;
      _trace('Health SDK configured.');
      return true;
    } on PlatformException catch (error, stackTrace) {
      _trace('Health SDK configure platform exception: ${error.code} ${error.message ?? ''}');
      developer.log(
        'Health SDK configure platform exception',
        name: 'HealthPackageClient',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  List<health.HealthDataType> _resolveSupportedTypesForCurrentPlatform({
    required List<health.HealthDataType> types,
    required String purpose,
  }) {
    final resolved = <health.HealthDataType>[];
    final seen = <health.HealthDataType>{};

    for (final type in types) {
      if (!seen.add(type)) {
        continue;
      }

      if (_sdk.isDataTypeAvailable(type)) {
        resolved.add(type);
      }
    }

    _trace(
      'Resolved $purpose types for ${Platform.operatingSystem}: '
      '${resolved.map((type) => type.name).join(', ')}',
    );
    return resolved;
  }

  void _trace(String message) {
    developer.log(message, name: 'HealthPackageClient');
    // ignore: avoid_print
    print('[HealthPackageClient] $message');
  }
}