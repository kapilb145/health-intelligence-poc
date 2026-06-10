import '../../domain/entities/health_data_mode.dart';
import '../../domain/entities/health_date_range.dart';
import '../../domain/entities/health_metric_type.dart';
import '../../domain/services/health_data_mode_controller.dart';
import '../models/health_metric_model.dart';
import 'health_data_source.dart';

class SwitchableHealthDataSource
    implements HealthDataSource, HealthDataModeController {
  SwitchableHealthDataSource({
    required this.mockDataSource,
    required this.deviceDataSource,
    HealthDataMode initialMode = HealthDataMode.mock,
  }) : _currentMode = initialMode;

  final HealthDataSource mockDataSource;
  final HealthDataSource deviceDataSource;

  HealthDataMode _currentMode;

  @override
  HealthDataMode get currentMode => _currentMode;

  @override
  Future<void> setMode(HealthDataMode mode) async {
    _currentMode = mode;
  }

  @override
  Future<List<HealthMetricModel>> getMetrics({
    required HealthMetricType type,
    required HealthDateRange range,
  }) {
    return _activeDataSource.getMetrics(type: type, range: range);
  }

  @override
  Future<List<HealthMetricModel>> getAllMetrics({
    required HealthDateRange range,
  }) {
    return _activeDataSource.getAllMetrics(range: range);
  }

  HealthDataSource get _activeDataSource {
    switch (_currentMode) {
      case HealthDataMode.mock:
        return mockDataSource;
      case HealthDataMode.device:
        return deviceDataSource;
    }
  }
}
