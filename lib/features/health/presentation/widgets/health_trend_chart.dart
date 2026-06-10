import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_unit.dart';
import '../../domain/entities/health_trend_point.dart';

class HealthTrendChart extends StatelessWidget {
  const HealthTrendChart({super.key, required this.points});

  final List<HealthTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (points.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No trend data available for the selected period.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));
    final spots = List<FlSpot>.generate(
      sorted.length,
      (index) => FlSpot(index.toDouble(), sorted[index].value),
      growable: false,
    );

    final values = sorted.map((point) => point.value).toList(growable: false);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final metricType = sorted.first.metricType;
    final yInterval = _calculateNiceInterval(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
    );
    final minY = _calculateNiceMinY(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
      interval: yInterval,
    );
    final maxY = _calculateNiceMaxY(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
      interval: yInterval,
      minY: minY,
    );
    final leftReservedSize = _leftReservedSize(
      minY: minY,
      maxY: maxY,
      metricType: metricType,
    );

    final maxX = sorted.length == 1 ? 1.0 : (sorted.length - 1).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              _averageLabel(metricType),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.all(10),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots
                          .map((spot) {
                            final index = spot.x.round();
                            if (index < 0 || index >= sorted.length) {
                              return null;
                            }
                            final point = sorted[index];
                            return LineTooltipItem(
                              '${_averageLabel(point.metricType)}\n${_formatValue(point.value)} ${_unitLabelForAverage(point.unit)}\n${_formatTooltipDate(point.date)}',
                              theme.textTheme.bodySmall!.copyWith(
                                color: colorScheme.onInverseSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          })
                          .toList(growable: false);
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: leftReservedSize,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (!_isValueNearInterval(
                          value,
                          minY: minY,
                          interval: yInterval,
                        )) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            _formatAxisValue(value, metricType: metricType),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (!_isIntegerTick(value)) {
                          return const SizedBox.shrink();
                        }

                        final index = value.toInt();
                        if (!_shouldShowBottomTitle(index, sorted.length) ||
                            index >= sorted.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _formatAxisDate(sorted[index].date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: colorScheme.outlineVariant),
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: sorted.length > 2,
                    curveSmoothness: 0.25,
                    color: colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.8,
                          color: colorScheme.primary,
                          strokeWidth: 1.5,
                          strokeColor: colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAxisDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTooltipDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  bool _shouldShowBottomTitle(int index, int total) {
    if (index < 0 || index >= total) {
      return false;
    }
    if (total <= 3) {
      return true;
    }
    if (index == 0 || index == total - 1) {
      return true;
    }

    final middle = (total - 1) / 2;
    return index == middle.round();
  }

  @visibleForTesting
  double calculateNiceIntervalForTest({
    required double minValue,
    required double maxValue,
    required HealthMetricType metricType,
  }) {
    return _calculateNiceInterval(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
    );
  }

  @visibleForTesting
  double calculateNiceMinYForTest({
    required double minValue,
    required double maxValue,
    required HealthMetricType metricType,
  }) {
    final interval = _calculateNiceInterval(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
    );
    return _calculateNiceMinY(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
      interval: interval,
    );
  }

  @visibleForTesting
  double calculateNiceMaxYForTest({
    required double minValue,
    required double maxValue,
    required HealthMetricType metricType,
  }) {
    final interval = _calculateNiceInterval(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
    );
    final minY = _calculateNiceMinY(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
      interval: interval,
    );
    return _calculateNiceMaxY(
      minValue: minValue,
      maxValue: maxValue,
      metricType: metricType,
      interval: interval,
      minY: minY,
    );
  }

  double _calculateNiceInterval({
    required double minValue,
    required double maxValue,
    required HealthMetricType metricType,
  }) {
    final range = (maxValue - minValue).abs();
    final minimumInterval = _minimumNiceInterval(metricType);
    if (range == 0) {
      return minimumInterval;
    }

    final roughInterval = range / 2.5;
    final niceInterval = _niceNumber(roughInterval);
    return math.max(minimumInterval, niceInterval);
  }

  double _calculateNiceMinY({
    required double minValue,
    required double maxValue,
    required HealthMetricType metricType,
    required double interval,
  }) {
    final hasNonNegativeDomain = _isNonNegativeDomain(metricType);
    var minY = (minValue / interval).floorToDouble() * interval;

    if (_isNear(minY, minValue) && minY - interval >= 0) {
      minY -= interval;
    }

    if (hasNonNegativeDomain && minY < 0) {
      minY = 0;
    }

    return minY;
  }

  double _calculateNiceMaxY({
    required double minValue,
    required double maxValue,
    required HealthMetricType metricType,
    required double interval,
    required double minY,
  }) {
    var maxY = (maxValue / interval).ceilToDouble() * interval;

    if (_isNear(maxY, maxValue)) {
      maxY += interval;
    }

    if ((maxY - minY) < interval * 2) {
      maxY = minY + interval * 2;
    }

    return maxY;
  }

  double _minimumNiceInterval(HealthMetricType metricType) {
    switch (metricType) {
      case HealthMetricType.steps:
        return 500;
      case HealthMetricType.restingHeartRate:
        return 10;
      case HealthMetricType.sleepDuration:
        return 1;
      case HealthMetricType.weight:
        return 1;
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
        return 10;
      case HealthMetricType.bloodGlucose:
        return 10;
      case HealthMetricType.oxygenSaturation:
        return 5;
      case HealthMetricType.heartRateVariability:
        return 10;
      case HealthMetricType.caloriesBurned:
        return 50;
      case HealthMetricType.bodyTemperature:
        return 1;
    }
  }

  bool _isNonNegativeDomain(HealthMetricType metricType) {
    switch (metricType) {
      case HealthMetricType.steps:
      case HealthMetricType.restingHeartRate:
      case HealthMetricType.sleepDuration:
      case HealthMetricType.weight:
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
      case HealthMetricType.bloodGlucose:
      case HealthMetricType.oxygenSaturation:
      case HealthMetricType.heartRateVariability:
      case HealthMetricType.caloriesBurned:
      case HealthMetricType.bodyTemperature:
        return true;
    }
  }

  double _niceNumber(double value) {
    if (value <= 0) {
      return 1;
    }

    final exponent = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    final normalized = value / exponent;
    final rounded = normalized <= 1
        ? 1.0
        : normalized <= 2
        ? 2.0
        : normalized <= 5
        ? 5.0
        : 10.0;
    return rounded * exponent;
  }

  bool _isNear(double a, double b) {
    return (a - b).abs() < 0.0001;
  }

  String _formatAxisValue(
    double value, {
    required HealthMetricType metricType,
  }) {
    switch (metricType) {
      case HealthMetricType.steps:
        return _formatStepsAxisValue(value);
      case HealthMetricType.restingHeartRate:
        return value.round().toString();
      case HealthMetricType.sleepDuration:
      case HealthMetricType.weight:
        return value.toStringAsFixed(1);
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
      case HealthMetricType.bloodGlucose:
      case HealthMetricType.oxygenSaturation:
      case HealthMetricType.heartRateVariability:
      case HealthMetricType.caloriesBurned:
      case HealthMetricType.bodyTemperature:
        if (value.truncateToDouble() == value) {
          return value.toStringAsFixed(0);
        }
        return value.toStringAsFixed(1);
    }
  }

  String _formatStepsAxisValue(double value) {
    final rounded = value.round();
    final absoluteRounded = rounded.abs();
    if (absoluteRounded >= 10000) {
      final thousands = (rounded / 1000).round();
      return '${thousands}k';
    }
    return rounded.toString();
  }

  @visibleForTesting
  String formatAxisValueForTest(double value, HealthMetricType metricType) {
    return _formatAxisValue(value, metricType: metricType);
  }

  String _formatValue(double value, {int decimals = 1}) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final withCommas = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    if (parts.length == 1 || parts.last == '0') {
      return withCommas;
    }
    return '$withCommas.${parts.last}';
  }

  String _averageLabel(HealthMetricType metricType) {
    switch (metricType) {
      case HealthMetricType.steps:
        return 'Steps';
      case HealthMetricType.restingHeartRate:
        return 'Average Heart Rate';
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
        return 'Average Blood Pressure';
      case HealthMetricType.weight:
        return 'Average Weight';
      case HealthMetricType.sleepDuration:
        return 'Average Sleep';
      case HealthMetricType.bloodGlucose:
        return 'Average Glucose';
      case HealthMetricType.oxygenSaturation:
        return 'Average Oxygen Saturation';
      case HealthMetricType.heartRateVariability:
        return 'Average HRV';
      case HealthMetricType.caloriesBurned:
        return 'Average Calories';
      case HealthMetricType.bodyTemperature:
        return 'Average Temperature';
    }
  }

  String _unitLabelForAverage(HealthUnit unit) {
    switch (unit) {
      case HealthUnit.count:
        return 'steps/day';
      case HealthUnit.bpm:
        return 'bpm';
      case HealthUnit.mmHg:
        return 'mmHg';
      case HealthUnit.kilogram:
        return 'kg';
      case HealthUnit.hours:
        return 'hours/day';
      case HealthUnit.mgDl:
        return 'mg/dL';
      case HealthUnit.percentage:
        return '%';
      case HealthUnit.celsius:
        return 'C';
      case HealthUnit.kcal:
        return 'kcal';
      case HealthUnit.miliseconds:
        return 'ms';
    }
  }

  bool _isIntegerTick(double value) {
    return (value - value.truncateToDouble()).abs() < 0.0001;
  }

  bool _isValueNearInterval(
    double value, {
    required double minY,
    required double interval,
  }) {
    if (interval <= 0) {
      return true;
    }

    final ratio = (value - minY) / interval;
    final nearest = ratio.roundToDouble();
    return (ratio - nearest).abs() < 0.02;
  }

  double _leftReservedSize({
    required double minY,
    required double maxY,
    required HealthMetricType metricType,
  }) {
    final longest =
        _formatAxisValue(minY, metricType: metricType).length >
            _formatAxisValue(maxY, metricType: metricType).length
        ? _formatAxisValue(minY, metricType: metricType)
        : _formatAxisValue(maxY, metricType: metricType);
    final estimate = longest.length * 7.5;
    return estimate < 54
        ? 54
        : estimate > 84
        ? 84
        : estimate;
  }
}
