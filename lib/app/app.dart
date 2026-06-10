


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_intelligence_poc/core/constants/app_constants.dart';
import 'package:health_intelligence_poc/core/di/injection_container.dart';
import 'package:health_intelligence_poc/core/theme/app_theme.dart';
import 'package:health_intelligence_poc/features/health/presentation/cubit/health_dashboard_cubit.dart';
import 'package:health_intelligence_poc/features/health/presentation/pages/health_dashboard_page.dart';

class HealthIntelligenceApp extends StatelessWidget {
  const HealthIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HealthDashboardCubit>(
      create: (_) => sl<HealthDashboardCubit>()..loadDashboardData(),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.light,
        home: const HealthDashboardPage(),
      ),
    );
  }
}