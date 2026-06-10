import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/health_date_range.dart';
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
              _PeriodSelector(
                selectedPeriod: state.selectedPeriod,
                selectedRange: state.selectedRange,
                customStartDate: state.customStartDate,
                customEndDate: state.customEndDate,
                onPeriodChanged: (period) {
                  context.read<HealthDashboardCubit>().loadDashboardData(
                        period: period,
                      );
                },
                onSelectCustomStartDate: (date) {
                  context.read<HealthDashboardCubit>().loadDashboardData(
                        period: HealthDashboardPeriod.custom,
                        customStartDate: date,
                      );
                },
                onSelectCustomEndDate: (date) {
                  context.read<HealthDashboardCubit>().loadDashboardData(
                        testDate: date,
                        period: HealthDashboardPeriod.custom,
                        customEndDate: date,
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

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.selectedRange,
    required this.customStartDate,
    required this.customEndDate,
    required this.onPeriodChanged,
    required this.onSelectCustomStartDate,
    required this.onSelectCustomEndDate,
  });

  final HealthDashboardPeriod selectedPeriod;
  final HealthDateRange selectedRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ValueChanged<HealthDashboardPeriod> onPeriodChanged;
  final ValueChanged<DateTime> onSelectCustomStartDate;
  final ValueChanged<DateTime> onSelectCustomEndDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Period:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 12),
              DropdownButton<HealthDashboardPeriod>(
                value: selectedPeriod,
                onChanged: (value) {
                  if (value != null) {
                    onPeriodChanged(value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: HealthDashboardPeriod.last7Days,
                    child: Text('Last 7 days'),
                  ),
                  DropdownMenuItem(
                    value: HealthDashboardPeriod.last30Days,
                    child: Text('Last 30 days'),
                  ),
                  DropdownMenuItem(
                    value: HealthDashboardPeriod.custom,
                    child: Text('Custom'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatRange(selectedRange),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (selectedPeriod == HealthDashboardPeriod.custom) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final initialDate = customStartDate ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      onSelectCustomStartDate(picked);
                    }
                  },
                  child: Text(
                    customStartDate == null
                        ? 'Select start date'
                        : 'Start: ${_formatDate(customStartDate!)}',
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final initialDate = customEndDate ?? customStartDate ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initialDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      onSelectCustomEndDate(picked);
                    }
                  },
                  child: Text(
                    customEndDate == null
                        ? 'Select end date'
                        : 'End: ${_formatDate(customEndDate!)}',
                  ),
                ),
              ],
            ),
          ],
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

    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _formatRange(HealthDateRange range) {
    return '${_formatDate(range.startDate)} - ${_formatDate(range.endDate)}';
  }
}