import 'package:flutter/material.dart';

class HealthMetricCard extends StatelessWidget {
  const HealthMetricCard({
    super.key,
    required this.title,
    this.average,
    this.unitLabel,
    this.dataPointCount,
    this.statusText,
  });

  final String title;
  final double? average;
  final String? unitLabel;
  final int? dataPointCount;
  final String? statusText;

  bool get _isAvailable =>
      average != null && unitLabel != null && dataPointCount != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_isAvailable) ...[
              Text(
                '${average!.toStringAsFixed(1)} $unitLabel',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Data points: $dataPointCount',
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                'Not available',
                style: theme.textTheme.titleMedium,
              ),
              if (statusText != null) ...[
                const SizedBox(height: 8),
                Text(
                  statusText!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}