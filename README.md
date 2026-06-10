# Health Intelligence POC

## Overview

This Flutter submission demonstrates a Health Intelligence proof of concept that:

- Connects with health providers
- Retrieves health metrics
- Calculates configurable averages
- Visualizes trend data

Supported providers:

- Google Health Connect (tested on Android device)
- Apple HealthKit integration path through the `health` package
- Mock provider for stable demos and testing

## Features

- Daily steps
- Resting heart rate
- Blood pressure
- Weight
- Sleep duration
- 7-day averages
- 30-day averages
- Custom date ranges
- Trend visualization
- Runtime health provider switching

## Architecture

The project follows Clean Architecture with feature-first organization.

Presentation Layer:

- Flutter UI
- Cubit state management
- Reusable widgets

Domain Layer:

- Entities
- Repository contracts
- Use cases
- Analytics services

Data Layer:

- Repository implementation
- Data sources
- HealthKit/Health Connect adapter
- DTO/model mapping

Flow:

```text
UI
 ↓
Cubit
 ↓
UseCase
 ↓
Repository Interface
 ↓
Repository Implementation
 ↓
HealthDataSource
 ↓
HealthKit / Health Connect / Mock
```

## Key Design Decisions

1. Provider abstraction
	HealthKit and Health Connect integrations are isolated from domain logic.

2. Generic `HealthMetric` entity
	New metrics can be introduced without architecture rewrites.

3. Result wrapper
	Success and failure paths are handled predictably across layers.

4. Dependency Injection
	Mock and real device data sources can be switched with minimal wiring changes.

5. Domain analytics service
	Calculation logic is reusable and independent of Flutter/platform APIs.

## Setup

```bash
flutter pub get
flutter run
```

## Data Source Switching

The app supports runtime switching from the dashboard toggle: Demo | Device.

Demo Mode:

- Uses `MockHealthDataSource`
- Provides sample data for demos and testing

Device Mode:

- Uses HealthKit / Health Connect
- Requests real health permissions
- Reads available device records

Initial mode can still be configured in `configureDependencies()`, and runtime mode changes are handled by `SwitchableHealthDataSource` without rebuilding DI.

## Android Health Connect

- Requires Google Health Connect availability on device
- Required permissions must be granted/configured
- Integration path has been tested on a physical Android device

## iOS HealthKit

- Requires HealthKit capability in the iOS target
- Requires Info.plist usage description entries
- Real device is required for meaningful health record validation

## Running Tests

```bash
flutter analyze
flutter test
```

## Current Limitations

- Health data availability depends on connected devices/apps
- Simulators may not provide real health records
- Some metrics require wearable devices

## Future Improvements

- Additional health metrics
- AI/ML insights
- Anomaly detection
- Cloud sync
- User goals
- Personalized recommendations
