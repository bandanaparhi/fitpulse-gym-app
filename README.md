# FitPulse Gym Management - Member Application 🏋️‍♂️

A comprehensive, production-ready Flutter gym management member application built with modern architecture, responsive layouts, and Material 3 design tokens.

---

## ✨ Features

- **🔐 Authentication**: Member login, account registration, and password recovery.
- **📊 Member Dashboard**: Overview of today's workout, daily nutrition targets, check-in QR shortcut, active membership status, and attendance KPIs.
- **💳 Membership Management**: Active plan breakdown, timeline visualization, agreement history, and plan renewal modal.
- **📅 Attendance Tracking**: Monthly visit calendar, consistency metrics, check-in and check-out history records with duration details.
- **💪 Workouts & Training**:
  - Assigned routine overview and weekly schedule.
  - Exercise breakdown with sets, reps, weight, rest timer, and instructions.
  - Interactive active workout logger with set-by-set completion tracking.
  - Post-workout completion summary and streak tracking.
- **📈 Fitness Progress**: Body weight and measurement tracking, metric/imperial unit switching (kg/lb, cm/in), interactive progress charts, and personal goal tracking.
- **🥗 Diet & Nutrition**: Assigned daily meal protocol, multi-day meal switcher, macronutrient calculations, and trainer meal notes.
- **🧘 Classes & Bookings**: Group fitness schedule, live seat capacities, category filtering, instant reservations, duplicate prevention, and booking cancellations.
- **🥊 My Trainer**: Personal trainer profile (Jordan Lee), qualifications, 1-on-1 session schedule, and in-app messaging.
- **🧾 Payments & Invoices**: Verified billing ledgers, tax invoice generation, receipt viewing, and PDF download simulation.
- **🔔 Notifications**: Push & in-app alerts, read/unread filters, mark all as read, and contextual route navigation.
- **📢 Announcements**: Published facility updates, equipment notices, and document attachments.
- **👤 Member Profile**: Monogram/photo identity card, immutable Member ID (`GM-1024`), contact info, emergency contacts, and profile editing.
- **⚙️ Settings**: Notification preference channel toggles, change password security, data privacy policy, and session logout with confirmation.
- **🛟 Help & Support**: Grounded gym FAQs with search and category filtering, configured staff contacts, phone-unavailable fallback notice, and feedback/issue reporting forms.

---

## 📱 Responsive Layouts

- **Desktop (>= 1024px)**: Persistent categorized dark sidebar, top header with member controls, and constrained content view.
- **Tablet (768px – 1023px)**: Icon-collapsed sidebar with tooltips and 2-column adaptive layouts.
- **Mobile (< 768px)**: Compact header with drawer trigger, bottom navigation bar (`AppBottomNav`), and full off-canvas navigation drawer.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Null-safe Dart)
- **UI System**: Material 3 with `package:material_ui/material_ui.dart`
- **State Management**: [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) (24 declared routes)
- **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Architecture**: Repository Pattern with Centralized Mock Repositories ready for Firebase/Firestore integration.

---

## 🧪 Testing & Code Quality

Run tests across all 16 test suites:
```bash
flutter test
```
*Current test suite: 63/63 passing tests.*

Run static analysis:
```bash
flutter analyze
```
*0 issues detected.*

---

## 🚀 Getting Started

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run on Chrome / Web**:
   ```bash
   flutter run -d chrome
   ```

3. **Run on macOS / Desktop**:
   ```bash
   flutter run -d macos
   ```

4. **Run on Mobile Simulator (iOS / Android)**:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is private and proprietary.
