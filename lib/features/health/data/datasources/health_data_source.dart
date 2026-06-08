abstract class HealthDataSource {
  Future<List<Map<String, dynamic>>> fetchMetrics({
    required DateTime startDate,
    required DateTime endDate,
  });
}