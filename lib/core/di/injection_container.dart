import 'dart:developer' as developer;

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
import '../../features/health/presentation/cubit/health_dashboard_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  bool useDeviceDataSource = false,
}) async {
  developer.log(
    'configureDependencies(useDeviceDataSource: $useDeviceDataSource)',
    name: 'DI',
  );

  if (sl.isRegistered<HealthDataSource>()) {
    developer.log('Resetting existing GetIt registrations.', name: 'DI');
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
      developer.log('Resolving HealthDataSource -> DeviceHealthDataSource', name: 'DI');
      return sl<DeviceHealthDataSource>();
    }
    developer.log('Resolving HealthDataSource -> MockHealthDataSource', name: 'DI');
    return sl<MockHealthDataSource>();
  });

  sl.registerLazySingleton<HealthRepository>(() => HealthRepositoryImpl(sl()));
  sl.registerLazySingleton<HealthAnalyticsService>(HealthAnalyticsService.new);
  sl.registerFactory(
    () => CalculateHealthMetricsSummary(sl(), sl()),
  );
  sl.registerFactory(() => HealthDashboardCubit(sl()));
}