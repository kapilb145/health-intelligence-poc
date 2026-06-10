import 'package:flutter/material.dart';

class HealthMetricCard extends StatelessWidget {
  const HealthMetricCard({
    super.key,
    required this.metricName,
    required this.icon,
    this.average,
    this.unitLabel,
    this.periodLabel,
    this.statusText,
  });

  final String metricName;
  final IconData icon;
  final double? average;
  final String? unitLabel;
  final String? periodLabel;
  final String? statusText;

  bool get _isAvailable => average != null && unitLabel != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    metricName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isAvailable) ...[
              RichText(
                text: TextSpan(
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(text: average!.toStringAsFixed(1)),
                    TextSpan(
                      text: ' $unitLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                periodLabel ?? 'average',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                'No data available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (statusText != null) ...[
                const SizedBox(height: 8),
                Text(
                  statusText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}