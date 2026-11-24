# FitPulse Gym Management — Agent Instruction & Specification Manual (AGENTS.md)

Welcome, AI Agent. This document serves as the authoritative operational manual, architectural specification, and design system reference for developing, maintaining, and extending the **FitPulse Gym Management Member Application**.

All AI agents, pairing assistants, and contributors operating within this repository must adhere strictly to the conventions, domain invariants, design tokens, and verification protocols outlined below.

---

## 1. System Identity & Mission

* **Project**: FitPulse Gym Management — Member Portal Application
* **Target Audience**: Gym members accessing personal fitness data, active training routines, class reservations, attendance metrics, membership agreements, trainer interactions, and billing history.
* **Agent Persona**: Senior Flutter & Cross-Platform Systems Engineer.
* **Engineering Principles**:
  * **Zero Hallucination / Ground Truth**: Never invent mock transactions, fake payment receipts, unsupported contact phone numbers, or synthetic trainer qualifications. If a service or integration is unavailable, display a designated empty, fallback, or status state.
  * **Strict Type Safety & Clean Architecture**: Maintain null-safe Dart, repository pattern abstraction, Riverpod state management, and separation of UI, business logic, and data.
  * **Flawless Responsiveness**: Guarantee zero RenderFlex overflows across desktop (≥1024px), tablet (768px–1023px), and mobile (<768px) viewport widths.
  * **100% Quality Gates**: All code changes must pass `flutter analyze` with 0 warnings/errors and maintain 100% passing tests across all test suites.

---

## 2. Technology Stack & Dependencies

| Layer | Technology | Key Packages |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.38+ / Dart 3.x (Null-safe) | `flutter`, `flutter_test` |
| **UI System** | Material 3 Design Tokens | `package:material_ui/material_ui.dart` |
| **State Management** | Flutter Riverpod | `flutter_riverpod: ^2.6.1` |
| **Routing** | GoRouter (Declarative Shell & Sub-routes) | `go_router: ^14.8.1` |
| **Data Visualization** | FL Chart | `fl_chart: ^0.70.2` |
| **Icons & Media** | Material Icons & Cupertino Icons | `cupertino_icons: ^1.0.8` |
| **Future Backend** | Ready for Firebase Auth & Cloud Firestore | Repository contracts with asynchronous Futures |

---

## 3. Repository Architecture & Layout

The project follows a **Feature-First Clean Architecture**:

```text
lib/
├── app/
│   ├── app.dart                    # MaterialApp entry, theme injection, router binding
│   ├── router.dart                 # Central GoRouter definition (24 distinct routes)
│   └── theme/
│       ├── app_colors.dart         # Semantic color tokens (dark charcoal, lime accent, neutrals)
│       ├── app_text_styles.dart    # Standardized typography scale
│       └── app_theme.dart          # M3 ThemeData, AppSpacing, and AppRadius tokens
├── core/
│   ├── constants/                  # Application-wide constants & keys
│   ├── errors/                     # Failure models and exception definitions
│   └── utils/                      # Date/currency formatters, validators, responsive helpers
├── data/
│   ├── models/                     # Strongly-typed data models (Immutable with copyWith)
│   ├── repositories/               # Repository interfaces and implementations
│   │   ├── mock_data.dart          # Centralized single-source-of-truth mock database
│   │   ├── member_repository.dart  # Member profile & membership contracts
│   │   ├── attendance_repository.dart
│   │   ├── workout_repository.dart
│   │   ├── class_repository.dart
│   │   ├── trainer_repository.dart
│   │   ├── payment_repository.dart
│   │   ├── settings_repository.dart
│   │   └── support_repository.dart
│   └── services/                   # Local storage, mock sync, and future API clients
├── features/
│   ├── announcements/              # Facility news, notices, and attachments
│   ├── attendance/                 # Check-in calendar, visit duration, and history records
│   ├── auth/                       # Login, Register, Forgot Password flows
│   ├── classes/                    # Class catalog, booking engine, seat capacity, cancellation
│   ├── dashboard/                  # Central member overview, quick actions, KPI summary cards
│   ├── diet/                       # Daily nutrition protocol, macro calculator, trainer notes
│   ├── landing/                    # Preserved initial starter page (/original-demo)
│   ├── membership/                 # Active plan breakdown, timeline, renewal modal
│   ├── notifications/              # Alert listings, unread filtering, mark-as-read actions
│   ├── payments/                   # Verified ledger history, itemized details, PDF tax receipts
│   ├── profile/                    # Profile card, contact details, edit form validation
│   ├── progress/                   # Weight & measurement logs, charts, unit conversion (Metric/Imperial)
│   ├── settings/                   # Notification channel preferences, change password, logout
│   ├── support/                    # Grounded gym FAQs, contact staff, feedback & ticket submission
│   ├── trainer/                    # Assigned trainer profile, session schedules, in-app messaging
│   └── workouts/                   # Active workout logger, routines, sets/reps/weight tracker
└── shared/
    ├── layout/                     # AppShell, AppSidebar, AppHeader, AppDrawer
    ├── navigation/                 # AppBottomNav (mobile), nav items configuration
    └── widgets/                    # SummaryCard, MetricBadge, StatusChip, EmptyStateView, AppButton
```

---

## 4. Design System & Token Guidelines

### UI Package Rule
* Always import and use `package:material_ui/material_ui.dart` across all UI widgets.
* Do not bypass tokens with raw hardcoded hexadecimal color codes or arbitrary magic numbers for padding.

### Semantic Color Tokens (`AppColors`)
* **Primary Dark Palette**:
  * `AppColors.darkCharcoal` (`0xFF111418`): Primary headers, desktop sidebar, dark container surfaces.
  * `AppColors.darkSurface` (`0xFF16191E`): Secondary dark panels.
  * `AppColors.darkElevated` (`0xFF1E2228`): Elevated cards on dark backgrounds.
  * `AppColors.darkBorder` (`0xFF2A2F37`): Subtle dark dividers.
* **Vibrant Lime-Green Accent**:
  * `AppColors.limeAccent` (`0xFF84CC16`): Primary CTAs, active status badges, workout streaks, progress graphs.
  * `AppColors.limeAccentLight` (`0xFFECFDF5`): Light badge backgrounds.
  * `AppColors.limeAccentDark` (`0xFF4D7C0F`): Border highlights and contrast text.
* **Canvas & Surface**:
  * `AppColors.scaffoldBackground` (`0xFFF7F8FA`): Light grey base canvas.
  * `AppColors.cardBackground` (`0xFFFFFFFF`): White elevated card container.
  * `AppColors.cardSubtleBg` (`0xFFF9FAFB`): Grouped list headers, table strips.
* **Status Colors**:
  * `AppColors.success` (`0xFF10B981`) & `AppColors.successBg` (`0xFFD1FAE5`)
  * `AppColors.warning` (`0xFFF59E0B`) & `AppColors.warningBg` (`0xFFFEF3C7`)
  * `AppColors.error` (`0xFFEF4444`) & `AppColors.errorBg` (`0xFFFEE2E2`)
  * `AppColors.info` (`0xFF3B82F6`) & `AppColors.infoBg` (`0xFFDBEAFE`)

### Spacing & Radius Tokens
* **Spacing (`AppSpacing`)**:
  * `xxs`: 2.0 | `xs`: 4.0 | `sm`: 8.0 | `md`: 16.0 | `lg`: 24.0 | `xl`: 32.0 | `xxl`: 48.0
* **Border Radii (`AppRadius`)**:
  * `sm`: 6.0 | `md`: 10.0 | `lg`: 14.0 | `xl`: 20.0 | `full`: 999.0

### Layout & Responsiveness Guidelines
* **Breakpoints**:
  * **Desktop (`≥ 1024px`)**: Persistent dark sidebar (`260px`), full header, multi-column grid/row layouts.
  * **Tablet (`768px – 1023px`)**: Compact/icon sidebar (`72px`), 2-column card layouts.
  * **Mobile (`< 768px`)**: Off-canvas sliding drawer, compact header, persistent `AppBottomNav`, single-column vertical stack.
* **Avoiding RenderFlex Overflow (Critical Rule)**:
  * **NEVER** use `GridView.count` with a rigid `childAspectRatio` for cards containing variable, multiline text, badges, or subtitles.
  * **ALWAYS** use `LayoutBuilder` with flexible rows and `Expanded` widgets on desktop/tablet, or `Wrap` with run spacing, allowing cards to calculate their vertical intrinsic height naturally without clipping.

---

## 5. Domain Invariants & Mock Data Truth

All member data stems from the single source of truth in `lib/data/repositories/mock_data.dart`.

### Authenticated Member Profile
* **Full Name**: Alex Morgan
* **Member ID**: `GM-1024` *(Immutable — cannot be edited or modified)*
* **Email**: `alex.morgan@fitpulse.demo`
* **Phone**: `+1 (555) 382-9104`
* **Membership Plan**: Annual All-Access Premium
* **Membership Status**: Active (Valid through Dec 30, 2026)
* **Assigned Personal Trainer**: Jordan Lee (CSCS, Certified Sports Nutritionist, Rating: 4.9★)

### Ground Truth Integrity Rules
1. **No Fake Payments**: Never create synthetic pending charges or fake success confirmations without an actual ledger entry.
2. **Offline Payment Notice**: When online payment processing is unconfigured, display a clear, professional prompt directing the member to the front desk.
3. **No Fabricated Policies**: Do not invent cancellation penalties, refund percentages, or facility rules.
4. **No Synthetic Contact Numbers**: If phone support is unconfigured, state that telephone support is currently offline and direct the member to the in-app feedback/issue form or front desk.
5. **Read-Only Invariants**: Member ID (`GM-1024`), Membership validity dates, and historical payment transactions are strictly read-only and must never be editable in the Profile or Settings screens.

---

## 6. Route Catalog (24 Routes)

All routes are registered in `lib/app/router.dart`:

| Route Path | Feature | Screen Class | Layout Shell |
| :--- | :--- | :--- | :--- |
| `/original-demo` | Landing | `OriginalLandingPage` | Standalone |
| `/login` | Auth | `LoginScreen` | Standalone |
| `/register` | Auth | `RegisterScreen` | Standalone |
| `/forgot-password` | Auth | `ForgotPasswordScreen` | Standalone |
| `/dashboard` | Dashboard | `DashboardScreen` | Member `AppShell` |
| `/membership` | Membership | `MembershipScreen` | Member `AppShell` |
| `/attendance` | Attendance | `AttendanceScreen` | Member `AppShell` |
| `/workouts` | Workouts | `WorkoutOverviewScreen` | Member `AppShell` |
| `/workouts/details` | Workouts | `WorkoutDetailsScreen` | Member `AppShell` |
| `/workouts/active` | Workouts | `ActiveWorkoutScreen` | Member `AppShell` |
| `/progress` | Progress | `ProgressScreen` | Member `AppShell` |
| `/diet` | Nutrition | `DietPlanScreen` | Member `AppShell` |
| `/classes` | Classes | `ClassListingScreen` | Member `AppShell` |
| `/classes/details` | Classes | `ClassDetailsScreen` | Member `AppShell` |
| `/classes/my-bookings` | Classes | `MyBookingsScreen` | Member `AppShell` |
| `/trainer` | Trainer | `TrainerScreen` | Member `AppShell` |
| `/payments` | Payments | `PaymentHistoryScreen` | Member `AppShell` |
| `/payments/details` | Payments | `PaymentDetailsScreen` | Member `AppShell` |
| `/notifications` | Notifications | `NotificationsScreen` | Member `AppShell` |
| `/announcements` | Announcements | `AnnouncementListingScreen` | Member `AppShell` |
| `/announcements/details`| Announcements | `AnnouncementDetailsScreen` | Member `AppShell` |
| `/profile` | Profile | `ProfileScreen` | Member `AppShell` |
| `/settings` | Settings | `SettingsScreen` | Member `AppShell` |
| `/support` | Support | `SupportScreen` | Member `AppShell` |

---

## 7. Quality Assurance & Verification Commands

Before concluding any work, the agent must run and verify:

### 1. Static Analysis
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze
```
* **Acceptance Criteria**: `No issues found!` (0 errors, 0 warnings, 0 lints).
* Address all null-aware recommendations (e.g. use `?element` instead of `if (element != null) element!`).

### 2. Comprehensive Test Suite
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter test
```
* **Acceptance Criteria**: All 16 test files pass cleanly (currently `63/63 tests passed`).
* Test files located in `test/`:
  * `widget_test.dart`, `dashboard_test.dart`, `membership_test.dart`, `attendance_test.dart`
  * `workout_test.dart`, `progress_test.dart`, `diet_plan_test.dart`, `classes_test.dart`
  * `trainer_test.dart`, `payments_test.dart`, `notifications_test.dart`, `announcements_test.dart`
  * `profile_test.dart`, `settings_test.dart`, `support_test.dart`, `auth_test.dart`

### 3. Hot Reload & Restart on Chrome Dev Server
* When the app is running in Chrome (`task-345`):
  * Hot reload: `r`
  * Hot restart: `R` (Always use `R` when modifying state structure, routes, or provider dependencies).

### 4. Git & VCS Discipline
* Commit messages must follow Conventional Commits:
  * `feat(feature-name): add new capability`
  * `fix(dashboard): eliminate RenderFlex bottom overflow on KPI summary cards`
  * `test(payments): add receipt download verification tests`
  * `refactor(shared): consolidate summary card layout tokens`

---

## 8. Agent Checklist for Adding New Features

When requested to build a new feature or view:

1. **Model First**: Define immutable Dart models with `copyWith` and serializable fields in `lib/data/models/`.
2. **Repository Abstraction**: Define an interface and add centralized mock data in `lib/data/repositories/mock_data.dart`.
3. **State Management**: Wire up Riverpod `StateNotifierProvider` or `ChangeNotifierProvider` to manage UI states.
4. **Screen Presentation**: Build the UI adhering strictly to `AppColors`, `AppSpacing`, and `AppRadius`.
5. **Responsive Wrapping**: Verify layouts on desktop (1280px), tablet (800px), and mobile (390px) widths.
6. **Register Route**: Add the route in `lib/app/router.dart` inside the `ShellRoute` if it belongs to the member portal.
7. **Automated Testing**: Author a comprehensive test file in `test/<feature>_test.dart` validating rendering, user interactions, form validation, and edge states.
8. **Verify & Push**: Run `flutter analyze`, run `flutter test`, commit to git, and push to origin.
