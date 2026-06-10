import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_unit.dart';
import '../../domain/entities/health_trend_point.dart';

class HealthTrendChart extends StatelessWidget {
  const HealthTrendChart({
    super.key,
    required this.points,
  });

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
    final valueRange = maxValue - minValue;
    final yPadding = valueRange == 0 ? (maxValue == 0 ? 1.0 : maxValue * 0.1) : valueRange * 0.2;
    final minY = (minValue - yPadding).clamp(0, double.infinity).toDouble();
    final maxY = (maxValue + yPadding).toDouble();
    final yInterval = _yInterval(minY: minY, maxY: maxY);
    final leftReservedSize = _leftReservedSize(minY: minY, maxY: maxY);
    final metricType = sorted.first.metricType;

    final maxX = sorted.length == 1 ? 1.0 : (sorted.length - 1).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _averageLabel(metricType),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Values are daily averages.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
                  return touchedSpots.map((spot) {
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
                  }).toList(growable: false);
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
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: leftReservedSize,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    if (!_isValueNearInterval(value, minY: minY, interval: yInterval)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        _formatAxisValue(value),
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
                    if (!_shouldShowBottomTitle(index, sorted.length) || index >= sorted.length) {
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

  double _yInterval({required double minY, required double maxY}) {
    final span = (maxY - minY).abs();
    if (span == 0) {
      return 1;
    }

    final rough = span / 3;
    if (rough <= 0) {
      return 1;
    }

    final exponent = math.pow(10, (math.log(rough.abs()) / math.ln10).floor()).toDouble();
    final normalized = rough / exponent;
    final step = normalized < 1.5
        ? 1.0
        : normalized < 3
            ? 2.0
            : normalized < 7
                ? 5.0
                : 10.0;
    return step * exponent;
  }

  String _formatAxisValue(double value) {
    if (value.abs() >= 1000) {
      return _formatValue(value, decimals: value.truncateToDouble() == value ? 0 : 1);
    }

    if (value.abs() >= 100) {
      return value.toStringAsFixed(0);
    }

    if (value.truncateToDouble() == value) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _formatValue(double value, {int decimals = 1}) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final withCommas = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    if (parts.length == 1 || parts.last == '0') {
      return withCommas;
    }
    return '$withCommas.${parts.last}';
  }

  String _averageLabel(HealthMetricType metricType) {
    switch (metricType) {
      case HealthMetricType.steps:
        return 'Average Steps';
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

  bool _isValueNearInterval(double value, {required double minY, required double interval}) {
    if (interval <= 0) {
      return true;
    }

    final ratio = (value - minY) / interval;
    final nearest = ratio.roundToDouble();
    return (ratio - nearest).abs() < 0.02;
  }

  double _leftReservedSize({required double minY, required double maxY}) {
    final longest = _formatAxisValue(minY).length > _formatAxisValue(maxY).length
        ? _formatAxisValue(minY)
        : _formatAxisValue(maxY);
    final estimate = longest.length * 7.5;
    return estimate < 54 ? 54 : estimate > 84 ? 84 : estimate;
  }

}