import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/health_metric_summary.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/entities/health_unit.dart';
import '../cubit/health_dashboard_cubit.dart';
import '../cubit/health_dashboard_state.dart';
import '../widgets/health_metric_card.dart';
import '../widgets/health_trend_chart.dart';

class HealthDashboardPage extends StatelessWidget {
  const HealthDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Intelligence Dashboard'),
      ),
      body: BlocBuilder<HealthDashboardCubit, HealthDashboardState>(
        builder: (context, state) {
          return Column(
            children: [
              _DateSelector(
                selectedDate: state.selectedTestDate,
                onSelectDate: (date) {
                  context.read<HealthDashboardCubit>().loadDashboardData(
                        testDate: date,
                      );
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildStateContent(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStateContent(HealthDashboardState state) {
    if (state is HealthDashboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is HealthDashboardError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.message,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state is HealthDashboardLoaded) {
      if (state.isEmpty && state.trendPoints.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No health data available for this date range yet.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Metric permissions/data are partially unavailable for this date range. Showing available trend data.',
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildCard(
                title: 'Steps Average',
                summary: state.metricSummaries[HealthMetricType.steps],
              ),
              _buildCard(
                title: 'Resting Heart Rate Average',
                summary: state.metricSummaries[HealthMetricType.restingHeartRate],
              ),
              _buildCard(
                title: 'Sleep Average',
                summary: state.metricSummaries[HealthMetricType.sleepDuration],
              ),
              _buildCard(
                title: 'Weight Average',
                summary: state.metricSummaries[HealthMetricType.weight],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Trend Overview',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          HealthTrendChart(points: state.trendPoints),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCard({
    required String title,
    required HealthMetricSummary? summary,
  }) {
    return SizedBox(
      width: 330,
      child: HealthMetricCard(
        title: title,
        average: summary?.average,
        unitLabel: summary != null ? _unitLabel(summary.unit) : null,
        dataPointCount: summary?.dataPointCount,
        statusText: summary == null ? 'No Health Connect data found' : null,
      ),
    );
  }

  String _unitLabel(HealthUnit unit) {
    switch (unit) {
      case HealthUnit.count:
        return 'count';
      case HealthUnit.bpm:
        return 'bpm';
      case HealthUnit.mmHg:
        return 'mmHg';
      case HealthUnit.kilogram:
        return 'kg';
      case HealthUnit.hours:
        return 'h';
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
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Selected test date: ${_formatDate(selectedDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (picked != null) {
                onSelectDate(picked);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}