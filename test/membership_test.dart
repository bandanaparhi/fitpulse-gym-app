import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/membership/presentation/membership_screen.dart';
import 'package:app/data/repositories/mock_data.dart';
import 'package:app/app/providers.dart';

void main() {
  group('Membership Screen Test Suite', () {
    testWidgets('MembershipScreen renders active plan details, timeline, and history', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MembershipScreen(),
            ),
          ),
        ),
      );

      // Settle async providers
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify Plan name and Member ID
      expect(find.text('My Membership'), findsOneWidget);
      expect(find.text(MockData.demoMembership.planName), findsWidgets);
      expect(find.textContaining('GM-1024'), findsWidgets);

      // Status indicator
      expect(find.text('ACTIVE'), findsWidgets);

      // Duration & Price
      expect(find.text('12 Months'), findsWidgets);
      expect(find.text('₹24,999'), findsWidgets);

      // Benefits list
      expect(find.text('Included Membership Benefits'), findsOneWidget);
      expect(find.text('Unlimited access to all gym locations'), findsOneWidget);
      expect(find.text('Free access to Steam & Sauna'), findsOneWidget);

      // Timeline
      expect(find.text('MEMBERSHIP TIMELINE'), findsOneWidget);
      expect(find.textContaining('days remaining'), findsOneWidget);

      // Previous membership history
      expect(find.text('Previous Membership History'), findsOneWidget);
      expect(find.text('Standard Fitness Tier'), findsOneWidget);
      expect(find.text('EXPIRED'), findsOneWidget);

      // Renew Membership CTA button
      expect(find.text('Renew Membership'), findsWidgets);
    });

    testWidgets('Renew Membership button opens modal with available plans', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MembershipScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final renewBtn = find.text('Renew Membership').first;
      await tester.tap(renewBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify modal opened and shows plans
      expect(find.text('Choose a renewal tier for Member ID: GM-1024'), findsOneWidget);
      expect(find.text('Premium All-Access'), findsWidgets);
      expect(find.text('Confirm Renewal'), findsOneWidget);

      // Scroll the modal's list to view other tiers
      await tester.scrollUntilVisible(
        find.text('Semi-Annual Elite'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Semi-Annual Elite'), findsOneWidget);
    });

    testWidgets('Displays empty state when member has no active membership', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MembershipScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Membership'), findsOneWidget);
      expect(find.text('Choose a Plan'), findsOneWidget);
    });
  });
}
