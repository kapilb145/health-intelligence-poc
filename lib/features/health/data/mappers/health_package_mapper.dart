import 'dart:io';

import 'package:health/health.dart' as health;

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

  HealthMetricType mapMetricType(health.HealthDataType healthDataType) {
    switch (healthDataType) {
      case health.HealthDataType.STEPS:
        return HealthMetricType.steps;
      case health.HealthDataType.RESTING_HEART_RATE:
      case health.HealthDataType.HEART_RATE:
        return HealthMetricType.restingHeartRate;
      case health.HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        return HealthMetricType.bloodPressureSystolic;
      case health.HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return HealthMetricType.bloodPressureDiastolic;
      case health.HealthDataType.WEIGHT:
        return HealthMetricType.weight;
      case health.HealthDataType.SLEEP_ASLEEP:
      case health.HealthDataType.SLEEP_SESSION:
        return HealthMetricType.sleepDuration;
      default:
        throw UnsupportedError(
          'Unsupported health data type: ${healthDataType.name}',
        );
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

  double _extractNumericValue(health.HealthValue rawValue) {
    if (rawValue is health.NumericHealthValue) {
      return rawValue.numericValue.toDouble();
    }

    throw UnsupportedError(
      'Unsupported health value type: ${rawValue.runtimeType}',
    );
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