import '../../domain/entities/health_data_provider.dart';
import '../../domain/entities/health_metric.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_unit.dart';

/// Data-layer representation used for serialization and provider mapping.
///
/// Converts between external/raw payloads and the provider-agnostic
/// domain entity to keep mapping concerns out of business logic.
class HealthMetricModel {
  const HealthMetricModel({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.source,
  });

  final String id;
  final HealthMetricType type;
  final double value;
  final HealthUnit unit;
  final DateTime recordedAt;
  final HealthDataProvider source;


  factory HealthMetricModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return HealthMetricModel(
      id: json['id'] as String,
      type: _parseMetricType(
        json['type'] as String,
      ),
      value: (json['value'] as num).toDouble(),
      unit: _parseUnit(
        json['unit'] as String,
      ),
      recordedAt: DateTime.parse(
        json['recordedAt'] as String,
      ),
      source: _parseDataProvider(
        json['source'] as String,
      ),
    );
  }


  factory HealthMetricModel.fromEntity(
    HealthMetric entity,
  ) {
    return HealthMetricModel(
      id: entity.id,
      type: entity.type,
      value: entity.value,
      unit: entity.unit,
      recordedAt: entity.recordedAt,
      source: entity.source,
    );
  }


  HealthMetric toEntity() {
    return HealthMetric(
      id: id,
      type: type,
      value: value,
      unit: unit,
      recordedAt: recordedAt,
      source: source,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'unit': unit.name,
      'recordedAt': recordedAt.toIso8601String(),
      'source': source.name,
    };
  }


  static HealthMetricType _parseMetricType(String raw) {
    return HealthMetricType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException(
        'Unknown HealthMetricType: $raw',
      ),
    );
  }


  static HealthUnit _parseUnit(String raw) {
    return HealthUnit.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException(
        'Unknown HealthUnit: $raw',
      ),
    );
  }


  static HealthDataProvider _parseDataProvider(String raw) {
    return HealthDataProvider.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException(
        'Unknown HealthDataProvider: $raw',
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HealthMetricModel &&
            other.id == id &&
            other.type == type &&
            other.value == value &&
            other.unit == unit &&
            other.recordedAt == recordedAt &&
            other.source == source;
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        value,
        unit,
        recordedAt,
        source,
      );



}