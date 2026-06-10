import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_trend_point.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';
import 'package:health_intelligence_poc/features/health/presentation/widgets/health_trend_chart.dart';

void main() {
  test('formats steps axis labels as whole numbers', () {
    const chart = HealthTrendChart(points: []);

    expect(
      chart.formatAxisValueForTest(4066.6, HealthMetricType.steps),
      '4067',
    );
    expect(
      chart.formatAxisValueForTest(4111.2, HealthMetricType.steps),
      '4111',
    );
  });

  test('formats large steps axis labels with compact k format', () {
    const chart = HealthTrendChart(points: []);

    expect(chart.formatAxisValueForTest(10000, HealthMetricType.steps), '10k');
  });

  test('formats heart rate axis labels as whole numbers', () {
    const chart = HealthTrendChart(points: []);

    expect(
      chart.formatAxisValueForTest(72.6, HealthMetricType.restingHeartRate),
      '73',
    );
  });

  test('formats sleep and weight axis labels with one decimal place', () {
    const chart = HealthTrendChart(points: []);

    expect(
      chart.formatAxisValueForTest(7.5, HealthMetricType.sleepDuration),
      '7.5',
    );
    expect(chart.formatAxisValueForTest(75.4, HealthMetricType.weight), '75.4');
  });

  test('calculates nice Y-axis bounds for steps range', () {
    const chart = HealthTrendChart(points: []);

    expect(
      chart.calculateNiceIntervalForTest(
        minValue: 3978,
        maxValue: 4111,
        metricType: HealthMetricType.steps,
      ),
      500,
    );
    expect(
      chart.calculateNiceMinYForTest(
        minValue: 3978,
        maxValue: 4111,
        metricType: HealthMetricType.steps,
      ),
      3500,
    );
    expect(
      chart.calculateNiceMaxYForTest(
        minValue: 3978,
        maxValue: 4111,
        metricType: HealthMetricType.steps,
      ),
      4500,
    );
  });

  test('calculates nice Y-axis bounds for heart rate range', () {
    const chart = HealthTrendChart(points: []);

    expect(
      chart.calculateNiceIntervalForTest(
        minValue: 68,
        maxValue: 75,
        metricType: HealthMetricType.restingHeartRate,
      ),
      10,
    );
    expect(
      chart.calculateNiceMinYForTest(
        minValue: 68,
        maxValue: 75,
        metricType: HealthMetricType.restingHeartRate,
      ),
      60,
    );
    expect(
      chart.calculateNiceMaxYForTest(
        minValue: 68,
        maxValue: 75,
        metricType: HealthMetricType.restingHeartRate,
      ),
      80,
    );
  });

  test('calculates nice Y-axis bounds for sleep range', () {
    const chart = HealthTrendChart(points: []);

    expect(
      chart.calculateNiceIntervalForTest(
        minValue: 6.5,
        maxValue: 8,
        metricType: HealthMetricType.sleepDuration,
      ),
      1,
    );
    expect(
      chart.calculateNiceMinYForTest(
        minValue: 6.5,
        maxValue: 8,
        metricType: HealthMetricType.sleepDuration,
      ),
      6,
    );
    expect(
      chart.calculateNiceMaxYForTest(
        minValue: 6.5,
        maxValue: 8,
        metricType: HealthMetricType.sleepDuration,
      ),
      9,
    );
  });

  testWidgets('shows empty state when no trend points exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HealthTrendChart(points: [])),
      ),
    );

    expect(
      find.text('No trend data available for the selected period.'),
      findsOneWidget,
    );
  });

  testWidgets('renders line chart for a single trend point', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthTrendChart(
            points: [
              HealthTrendPoint(
                date: DateTime(2026, 1, 7),
                value: 8542,
                metricType: HealthMetricType.steps,
                unit: HealthUnit.count,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('renders line chart for multiple trend points', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HealthTrendChart(
            points: [
              HealthTrendPoint(
                date: DateTime(2026, 1, 1),
                value: 7000,
                metricType: HealthMetricType.steps,
                unit: HealthUnit.count,
              ),
              HealthTrendPoint(
                date: DateTime(2026, 1, 8),
                value: 8500,
                metricType: HealthMetricType.steps,
                unit: HealthUnit.count,
              ),
              HealthTrendPoint(
                date: DateTime(2026, 1, 15),
                value: 9200,
                metricType: HealthMetricType.steps,
                unit: HealthUnit.count,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(LineChart), findsOneWidget);
  });
}
