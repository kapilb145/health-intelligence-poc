import 'package:flutter/material.dart';
import 'package:health_intelligence_poc/app/app.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(
    useDeviceDataSource: true,
  );
  runApp(const HealthIntelligenceApp());
}


