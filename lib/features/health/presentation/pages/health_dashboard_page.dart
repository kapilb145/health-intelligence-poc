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
        toolbarHeight: 74,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Health Intelligence'),
            SizedBox(height: 2),
            Text(
              'Health averages and trends',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
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
              const SizedBox(height: 6),
              Expanded(
                child: _buildStateContent(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, HealthDashboardState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is HealthDashboardLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading health insights...'),
          ],
        ),
      );
    }

    if (state is HealthDashboardError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 42,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load dashboard data',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  context.read<HealthDashboardCubit>().loadDashboardData(
                        testDate: state.selectedTestDate,
                        period: state.selectedPeriod,
                        customStartDate: state.customStartDate,
                        customEndDate: state.customEndDate,
                      );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is HealthDashboardLoaded) {
      if (state.isEmpty && state.trendPoints.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 46,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No health data available',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try changing the selected period or add more records in your health provider.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
         
          Text(
            'Some metrics may be unavailable if no Health Connect or HealthKit records exist.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _buildSummaryGrid(
            context: context,
            state: state,
            periodLabel: _periodLabel(state.selectedPeriod),
          ),
          const SizedBox(height: 16),
          Text(
            'Health Trends',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: HealthTrendChart(points: state.trendPoints),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSummaryGrid({
    required BuildContext context,
    required HealthDashboardLoaded state,
    required String periodLabel,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final crossAxisCount = maxWidth < 540
            ? 1
            : maxWidth < 860
                ? 2
                : 3;
        const spacing = 12.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final cardWidth = (maxWidth - totalSpacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildCard(
              width: cardWidth,
              metricName: 'Steps',
              icon: Icons.directions_walk,
              periodLabel: periodLabel == 'Last 7 days' || periodLabel == 'Last 30 days'
                  ? 'avg/day'
                  : 'average',
              summary: state.metricSummaries[HealthMetricType.steps],
            ),
            _buildCard(
              width: cardWidth,
              metricName: 'Heart Rate',
              icon: Icons.favorite,
              periodLabel: 'average',
              summary: state.metricSummaries[HealthMetricType.restingHeartRate],
            ),
            _buildCard(
              width: cardWidth,
              metricName: 'Sleep',
              icon: Icons.bedtime,
              periodLabel: 'average',
              summary: state.metricSummaries[HealthMetricType.sleepDuration],
            ),
            _buildCard(
              width: cardWidth,
              metricName: 'Weight',
              icon: Icons.monitor_weight,
              periodLabel: 'average',
              summary: state.metricSummaries[HealthMetricType.weight],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required double width,
    required String metricName,
    required IconData icon,
    required String periodLabel,
    required HealthMetricSummary? summary,
  }) {
    return SizedBox(
      width: width,
      child: HealthMetricCard(
        metricName: metricName,
        icon: icon,
        average: summary?.average,
        unitLabel: summary != null ? _unitLabel(summary.unit) : null,
        periodLabel: periodLabel,
        statusText: summary == null ? 'No data available for selected period' : null,
      ),
    );
  }

  String _periodLabel(HealthDashboardPeriod period) {
    switch (period) {
      case HealthDashboardPeriod.last7Days:
        return 'Last 7 days';
      case HealthDashboardPeriod.last30Days:
        return 'Last 30 days';
      case HealthDashboardPeriod.custom:
        return 'Custom';
    }
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
        return 'hrs';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Period:',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                DropdownButton<HealthDashboardPeriod>(
                  value: selectedPeriod,
                  underline: const SizedBox.shrink(),
                  isDense: true,
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (selectedPeriod == HealthDashboardPeriod.custom) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
