# ObserVita Health Intelligence POC - Development Instructions

## Project Context

This project is a Flutter proof-of-concept for a B2B2C health intelligence platform.

The goal is NOT only to build a working demo. The goal is to demonstrate:

- Production-quality Flutter architecture
- Maintainable code
- Scalable health data processing
- HealthKit / Google Health Connect integration readiness
- Clean service abstraction
- Data visualization
- Future AI/ML extensibility

Assume this codebase could evolve into a real healthcare platform.

---

# Architecture Rules

Use Clean Architecture with feature-first organization.

Follow this structure:

lib/

core/
- constants
- errors
- exceptions
- utils
- extensions
- dependency injection
- common widgets
- theme

features/

health/

data/
- models
- datasources
- repositories

domain/
- entities
- repositories
- usecases
- services

presentation/
- bloc/cubit
- pages
- widgets


Dependency direction:

Presentation
      |
      ↓
Domain
      |
      ↓
Data

Never allow UI to directly communicate with APIs, HealthKit, Health Connect, or storage.

---

# State Management

Use Bloc/Cubit.

Rules:

- UI contains no business logic
- Bloc/Cubit coordinates user actions
- UseCases contain application logic
- Repository abstracts data sources

Flow:

Widget
 → Cubit/Bloc
 → UseCase
 → Repository Interface
 → Repository Implementation
 → DataSource

---

# Health Data Design

Do NOT create separate hardcoded services for each metric.

Avoid:

StepService
HeartRateService
WeightService

Create generic scalable models.

Example:

HealthMetric {
 id,
 type,
 value,
 unit,
 recordedAt,
 source
}

Supported metrics initially:

- steps
- resting heart rate
- blood pressure
- weight
- sleep duration

Design must allow future metrics:

- glucose
- oxygen saturation
- HRV
- calories
- temperature
- wearable data

without architecture changes.

---

# Health Provider Abstraction

Never directly couple app logic with Apple HealthKit or Google Health Connect.

Create abstraction:

HealthDataSource

Implement:

HealthConnectDataSource
MockHealthDataSource

Future support:

AppleHealthKitDataSource
FitbitDataSource
GarminDataSource


The app should work with mock data when real device data is unavailable.

---

# Analytics Engine

Create reusable calculation services.

Support:

- 7 day averages
- 30 day averages
- custom date ranges

Input:

testDate
metricType
period

Example:

Calculate average steps for 7 days before test date.

Business calculation must NOT exist inside UI.

---

# Error Handling

Use structured error handling.

Do not throw raw exceptions into UI.

Create:

Failure
Result/Either pattern if appropriate

Handle:

- permission denied
- unavailable health data
- empty data
- API failures

---

# Healthcare Privacy Principles

Follow healthcare-aware development practices.

Rules:

- Do not log sensitive health data
- Request minimum permissions required
- Keep data access separated
- No secrets inside repository
- Prepare architecture for secure storage

---

# UI/UX Requirements

Create clean health dashboard.

Include:

Metric cards:
- Steps average
- Heart rate average
- Sleep average
- Weight trend

Charts:

Use fl_chart.

Show:

- multiple test dates
- trend visualization
- average changes over time

UI should look like a modern health intelligence product.

---

# Code Quality

Follow:

- SOLID principles
- dependency injection
- small classes
- reusable widgets
- meaningful naming

Avoid:

- God classes
- business logic in widgets
- duplicated code
- hardcoded values

---

# Git Workflow

Create meaningful commits.

Examples:

chore: initialize flutter project

feat: add health domain entities

feat: implement health repository abstraction

feat: add mock health data provider

feat: implement average calculation service

feat: add health dashboard visualization

docs: add architecture documentation


Never create one large final commit.

---

# Documentation Required

Maintain README.md containing:

- Project overview
- Architecture explanation
- Setup steps
- Health integration approach
- Calculation logic
- Design decisions
- Limitations
- Future improvements

Include future scaling ideas:

- Firebase sync
- Cloud Functions
- AI insight engine
- wearable integrations

---

# AI/ML Future Direction

Keep architecture ready for:

Health Data
    |
Analytics Engine
    |
AI Service Layer
    |
Personalized Insights

Do not mix AI logic with Flutter UI.
