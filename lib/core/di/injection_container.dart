import 'package:get_it/get_it.dart';

import '../../features/health/data/datasources/health_data_source.dart';
import '../../features/health/data/datasources/mock_health_data_source.dart';
import '../../features/health/data/repositories/health_repository_impl.dart';
import '../../features/health/domain/repositories/health_repository.dart';
import '../../features/health/domain/services/health_analytics_service.dart';
import '../../features/health/domain/usecases/calculate_health_metrics_summary.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton<MockHealthDataSource>(MockHealthDataSource.new);
  sl.registerLazySingleton<HealthDataSource>(() => sl<MockHealthDataSource>());
  sl.registerLazySingleton<HealthRepository>(() => HealthRepositoryImpl(sl()));
  sl.registerLazySingleton<HealthAnalyticsService>(HealthAnalyticsService.new);
  sl.registerFactory(
    () => CalculateHealthMetricsSummary(sl(), sl()),
  );
}