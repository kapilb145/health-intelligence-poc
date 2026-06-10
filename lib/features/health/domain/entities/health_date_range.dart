/// Centralized date window used by analytics and repository queries.
///
/// Keeps 7-day, 30-day, and custom range rules in one place so
/// period boundaries stay consistent across features.
class HealthDateRange {
  HealthDateRange._({
    required this.startDate,
    required this.endDate,
  }) : assert(
          !startDate.isAfter(endDate),
          'startDate must be before or equal to endDate',
        );

  final DateTime startDate;
  final DateTime endDate;

  factory HealthDateRange.last7Days(DateTime testDate) {
    final previousDay = _atStartOfDay(
      testDate,
    ).subtract(
      const Duration(days: 1),
    );

    return HealthDateRange._(
      startDate: previousDay.subtract(
        const Duration(days: 6),
      ),
      endDate: _atEndOfDay(previousDay),
    );
  }

  factory HealthDateRange.last30Days(DateTime testDate) {
    final previousDay = _atStartOfDay(
      testDate,
    ).subtract(
      const Duration(days: 1),
    );

    return HealthDateRange._(
      startDate: previousDay.subtract(
        const Duration(days: 29),
      ),
      endDate: _atEndOfDay(previousDay),
    );
  }

  factory HealthDateRange.custom(
    DateTime start,
    DateTime end,
  ) {
    return HealthDateRange._(
      startDate: _atStartOfDay(start),
      endDate: _atEndOfDay(end),
    );
  }

  static DateTime _atStartOfDay(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  static DateTime _atEndOfDay(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      23,
      59,
      59,
      999,
      999,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HealthDateRange &&
            other.startDate == startDate &&
            other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
        startDate,
        endDate,
      );
}