import 'package:get_it/get_it.dart';

import '../../features/health/data/datasources/device_health_data_source.dart';
import '../../features/health/data/datasources/health_data_source.dart';
import '../../features/health/data/datasources/health_package_client.dart';
import '../../features/health/data/datasources/mock_health_data_source.dart';
import '../../features/health/data/mappers/health_package_mapper.dart';
import '../../features/health/data/repositories/health_repository_impl.dart';
import '../../features/health/domain/repositories/health_repository.dart';
import '../../features/health/domain/services/health_analytics_service.dart';
import '../../features/health/domain/usecases/calculate_health_metrics_summary.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  bool useDeviceDataSource = false,
}) async {
  if (sl.isRegistered<HealthDataSource>()) {
    await sl.reset();
  }

  sl.registerLazySingleton<MockHealthDataSource>(MockHealthDataSource.new);
  sl.registerLazySingleton<HealthPackageMapper>(HealthPackageMapper.new);
  sl.registerLazySingleton<HealthPackageClient>(HealthPackageClientImpl.new);
  sl.registerLazySingleton<DeviceHealthDataSource>(
    () => DeviceHealthDataSource(
      client: sl(),
      mapper: sl(),
    ),
  );

  sl.registerLazySingleton<HealthDataSource>(() {
    if (useDeviceDataSource) {
      return sl<DeviceHealthDataSource>();
    }
    return sl<MockHealthDataSource>();
  });

  sl.registerLazySingleton<HealthRepository>(() => HealthRepositoryImpl(sl()));
  sl.registerLazySingleton<HealthAnalyticsService>(HealthAnalyticsService.new);
  sl.registerFactory(
    () => CalculateHealthMetricsSummary(sl(), sl()),
  );
}