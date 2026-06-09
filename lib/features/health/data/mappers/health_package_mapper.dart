import 'dart:io';

import '../datasources/health_package_client.dart';
import '../../domain/entities/health_data_provider.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_unit.dart';
import '../models/health_metric_model.dart';

class HealthPackageMapper {
  const HealthPackageMapper();

  HealthMetricModel mapDataPoint(HealthPackageDataPoint dataPoint) {
    final metricType = mapMetricType(dataPoint.type);
    final unit = mapUnit(metricType);
    final value = _extractNumericValue(dataPoint.value);
    final recordedAt = dataPoint.dateFrom;

    return HealthMetricModel(
      id: dataPoint.id,
      type: metricType,
      value: value,
      unit: unit,
      recordedAt: recordedAt,
      source: _mapProvider(),
    );
  }

  HealthMetricType mapMetricType(dynamic healthDataType) {
    final typeName = healthDataType.toString().split('.').last.toUpperCase();

    switch (typeName) {
      case 'STEPS':
        return HealthMetricType.steps;
      case 'RESTING_HEART_RATE':
        return HealthMetricType.restingHeartRate;
      case 'BLOOD_PRESSURE_SYSTOLIC':
        return HealthMetricType.bloodPressureSystolic;
      case 'BLOOD_PRESSURE_DIASTOLIC':
        return HealthMetricType.bloodPressureDiastolic;
      case 'WEIGHT':
      case 'BODY_MASS':
        return HealthMetricType.weight;
      case 'SLEEP_ASLEEP':
      case 'SLEEP_SESSION':
        return HealthMetricType.sleepDuration;
      default:
        throw UnsupportedError('Unsupported health data type: $typeName');
    }
  }

  HealthUnit mapUnit(HealthMetricType metricType) {
    switch (metricType) {
      case HealthMetricType.steps:
        return HealthUnit.count;
      case HealthMetricType.restingHeartRate:
        return HealthUnit.bpm;
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
        return HealthUnit.mmHg;
      case HealthMetricType.weight:
        return HealthUnit.kilogram;
      case HealthMetricType.sleepDuration:
        return HealthUnit.hours;
      case HealthMetricType.bloodGlucose:
        return HealthUnit.mgDl;
      case HealthMetricType.oxygenSaturation:
        return HealthUnit.percentage;
      case HealthMetricType.heartRateVariability:
        return HealthUnit.miliseconds;
      case HealthMetricType.caloriesBurned:
        return HealthUnit.kcal;
      case HealthMetricType.bodyTemperature:
        return HealthUnit.celsius;
    }
  }

  double _extractNumericValue(dynamic rawValue) {
    if (rawValue is num) {
      return rawValue.toDouble();
    }

    final fromNumericValue = _tryReadNumericValue(rawValue);
    if (fromNumericValue != null) {
      return fromNumericValue;
    }

    throw UnsupportedError('Unsupported health value type: ${rawValue.runtimeType}');
  }

  double? _tryReadNumericValue(dynamic rawValue) {
    try {
      final candidate = (rawValue as dynamic).numericValue;
      if (candidate is num) {
        return candidate.toDouble();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  HealthDataProvider _mapProvider() {
    if (Platform.isIOS) {
      return HealthDataProvider.appleHealthKit;
    }
    if (Platform.isAndroid) {
      return HealthDataProvider.googleHealthConnect;
    }
    return HealthDataProvider.wearable;
  }
}