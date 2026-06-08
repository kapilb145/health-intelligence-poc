import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const HealthIntelligenceApp());
}

class HealthIntelligenceApp extends StatelessWidget {
  const HealthIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text('Health Intelligence POC - Architecture Foundation'),
        ),
      ),
    );
  }
}
