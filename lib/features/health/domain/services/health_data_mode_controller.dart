import '../entities/health_data_mode.dart';

abstract class HealthDataModeController {
  HealthDataMode get currentMode;

  Future<void> setMode(HealthDataMode mode);
}
