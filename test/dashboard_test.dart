import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app/data/repositories/mock_data.dart';

void main() {
  group('Member Dashboard Test Suite', () {
    testWidgets('Dashboard renders all member details and metrics', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DashboardScreen(),
            ),
          ),
        ),
      );

      // Allow async Riverpod providers to resolve mock data
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 1. Personalized welcome & profile
      expect(find.textContaining('Alex Morgan'), findsWidgets);
      expect(find.textContaining('GM-1024'), findsWidgets);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);

      // 2. Membership status, remaining days, and expiry date
      expect(find.text(MockData.demoMember.membershipPlan), findsWidgets);
      expect(find.text(MockData.demoMember.membershipStatus.toUpperCase()), findsWidgets);
      expect(find.textContaining('days left'), findsWidgets);
      expect(find.textContaining('December 30, 2026'), findsWidgets);

      // 2b. Daily fitness progress summary
      expect(find.text('Daily Fitness Progress'), findsOneWidget);
      expect(find.text('Today Check-In'), findsOneWidget);
      expect(find.text('Body Weight'), findsOneWidget);
      expect(find.text('Daily Nutrition'), findsOneWidget);

      // 3. Monthly attendance
      expect(find.text('18 visits'), findsWidgets);

      // 4. Pending payment
      expect(find.text('₹0'), findsWidgets);
      expect(find.text('PAID IN FULL'), findsOneWidget);

      // 5. Assigned trainer
      expect(find.text(MockData.demoMember.assignedTrainer), findsWidgets);

      // 6. Quick actions
      expect(find.text('Start Workout'), findsWidgets);
      expect(find.text('Check-in'), findsWidgets);
      expect(find.text('Book a Class'), findsOneWidget);
      expect(find.text('View Progress'), findsOneWidget);

      // 7. Today's Workout section
      expect(find.text("Today's Workout"), findsOneWidget);
      expect(find.text('Upper Body Power & Hypertrophy'), findsOneWidget);

      // 8. Weekly attendance chart
      expect(find.text('Weekly Attendance & Activity'), findsOneWidget);
      expect(find.textContaining('5 / 7 Days'), findsOneWidget);

      // 9. Upcoming class booking
      expect(find.text('Upcoming Class'), findsOneWidget);
      expect(find.text('High-Octane Spin Revolution'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsOneWidget);

      // 10. Gym announcements
      expect(find.text('Gym Announcements'), findsOneWidget);
      expect(find.text('Holiday Schedule & Facility Maintenance Notice'), findsOneWidget);
    });
  });
}
