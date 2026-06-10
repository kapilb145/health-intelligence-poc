import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_metric_type.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_trend_point.dart';
import 'package:health_intelligence_poc/features/health/domain/entities/health_unit.dart';
import 'package:health_intelligence_poc/features/health/presentation/widgets/health_trend_chart.dart';

void main() {
  testWidgets('shows empty state when no trend points exist', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HealthTrendChart(points: []),
        ),
      ),
    );

    expect(find.text('No trend data available for the selected period.'), findsOneWidget);
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
