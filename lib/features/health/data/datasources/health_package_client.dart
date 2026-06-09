import 'package:health/health.dart' as health;

class HealthPackageDataPoint {
  const HealthPackageDataPoint({
    required this.id,
    required this.type,
    required this.value,
    required this.dateFrom,
    required this.dateTo,
  });

  final String id;
  final dynamic type;
  final dynamic value;
  final DateTime dateFrom;
  final DateTime dateTo;
}

abstract class HealthPackageClient {
  Future<bool> isDataAvailable();

  Future<bool> requestReadAuthorization({
    required List<dynamic> types,
  });

  Future<List<HealthPackageDataPoint>> getHealthData({
    required DateTime start,
    required DateTime end,
    required List<dynamic> types,
  });
}

class HealthPackageClientImpl implements HealthPackageClient {
  HealthPackageClientImpl({health.Health? sdk}) : _sdk = sdk ?? health.Health();

  final health.Health _sdk;
  bool _isConfigured = false;

  @override
  Future<bool> isDataAvailable() async {
    await _ensureConfigured();
    return _sdk.isHealthConnectAvailable();
  }

  @override
  Future<bool> requestReadAuthorization({
    required List<dynamic> types,
  }) async {
    await _ensureConfigured();
    final typed = types.cast<health.HealthDataType>();

    final readAccess = _readAccessEnum();
    if (readAccess != null) {
      final permissions = List.generate(typed.length, (_) => readAccess);
      try {
        return await _sdk.requestAuthorization(
          typed,
          permissions: permissions,
        );
      } catch (_) {
        // Backward compatibility for older plugin signatures.
      }
    }

    return _sdk.requestAuthorization(typed);
  }

  @override
  Future<List<HealthPackageDataPoint>> getHealthData({
    required DateTime start,
    required DateTime end,
    required List<dynamic> types,
  }) async {
    await _ensureConfigured();
    final typed = types.cast<health.HealthDataType>();
    final points = await _sdk.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: typed,
    );

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

  health.HealthDataAccess? _readAccessEnum() {
    try {
      return health.HealthDataAccess.values.firstWhere(
        (value) => value.name.toUpperCase() == 'READ',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) {
      return;
    }

    await _sdk.configure();
    _isConfigured = true;
  }
}