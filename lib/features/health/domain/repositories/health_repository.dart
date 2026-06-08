import '../../../../core/result/result.dart';

abstract class HealthRepository {
  Future<Result<List<Map<String, dynamic>>>> fetchMetrics({
    required DateTime startDate,
    required DateTime endDate,
  });
}