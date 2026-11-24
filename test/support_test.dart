import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/support/presentation/support_screen.dart';
import 'package:app/features/support/presentation/widgets/contact_staff_card.dart';
import 'package:app/features/support/presentation/widgets/faq_section.dart';
import 'package:app/features/support/presentation/widgets/feedback_form_card.dart';
import 'package:app/shared/widgets/primary_button.dart';
import 'package:app/data/repositories/support_repository.dart';
import 'package:app/app/providers.dart';

void main() {
  group('Help and Support Feature Test Suite', () {
    testWidgets('SupportScreen renders all sections: FAQs, contact staff, and feedback/issue form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSupportRepo = MockSupportRepository(latency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportRepositoryProvider.overrideWithValue(testSupportRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SupportScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Page Title & Subtitle
      expect(find.text('Help Desk & Support'), findsOneWidget);
      expect(find.textContaining('Find answers in our gym FAQs, contact on-site staff'), findsOneWidget);

      // Section 1: FAQs
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('Search questions by keyword...'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Facility & Access'), findsWidgets);
      expect(find.text('Classes & Bookings'), findsWidgets);
      expect(find.text('Workouts & Training'), findsWidgets);
      expect(find.text('Billing & Accounts'), findsWidgets);

      // Verify FAQ Questions
      expect(find.text('How do I check in to the gym facility?'), findsOneWidget);
      expect(find.text('How do I book a group fitness class?'), findsOneWidget);

      // Section 2: Contact Staff & Front Desk
      expect(find.text('Contact Gym Staff & Front Desk'), findsOneWidget);
      expect(find.text('support@fitpulse.com'), findsOneWidget);
      expect(find.text('Phone Support Not Configured'), findsOneWidget);
      expect(find.textContaining('Direct phone hotline support is not configured for this facility'), findsOneWidget);
      expect(find.text('FitPulse Fitness Hub, Sector 42, Bengaluru, Karnataka 560001'), findsOneWidget);
      expect(find.text('Jordan Lee'), findsOneWidget);

      // Section 3: Submit Feedback / Report an Issue
      expect(find.text('Submit Member Feedback'), findsOneWidget);
      expect(find.text('Submit Feedback'), findsWidgets);
      expect(find.text('Report an Issue'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
      expect(find.text('Subject *'), findsOneWidget);
      expect(find.text('Message *'), findsOneWidget);
    });

    testWidgets('FAQs filter by category and search keyword', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSupportRepo = MockSupportRepository(latency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportRepositoryProvider.overrideWithValue(testSupportRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FaqSection(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Initially all FAQs rendered
      expect(find.text('How do I check in to the gym facility?'), findsOneWidget);
      expect(find.text('Where do I find payment records and official receipts?'), findsOneWidget);

      // Filter by "Classes & Bookings" chip
      await tester.tap(find.widgetWithText(FilterChip, 'Classes & Bookings'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Classes questions visible, Billing questions hidden
      expect(find.text('How do I book a group fitness class?'), findsOneWidget);
      expect(find.text('Where do I find payment records and official receipts?'), findsNothing);

      // Reset to "All"
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Search keyword "receipts"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'receipts');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Where do I find payment records and official receipts?'), findsOneWidget);
      expect(find.text('How do I check in to the gym facility?'), findsNothing);

      // Expanding FAQ tile shows answer
      await tester.tap(find.text('Where do I find payment records and official receipts?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('downloadable PDF receipts with tax invoice breakdowns'), findsOneWidget);
    });

    testWidgets('ContactStaffCard displays configured contacts and clear message when phone is unavailable', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSupportRepo = MockSupportRepository(latency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportRepositoryProvider.overrideWithValue(testSupportRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ContactStaffCard(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Official email
      expect(find.text('support@fitpulse.com'), findsOneWidget);

      // Clear unavailable phone banner (no invented phone numbers)
      expect(find.text('Phone Support Not Configured'), findsOneWidget);
      expect(find.textContaining('Direct phone hotline support is not configured for this facility'), findsOneWidget);

      // Operating hours & location
      expect(find.text('Mon–Sat: 6:00 AM – 10:00 PM | Sun: 7:00 AM – 2:00 PM'), findsOneWidget);
      expect(find.text('FitPulse Fitness Hub, Sector 42, Bengaluru, Karnataka 560001'), findsOneWidget);

      // Coach contact
      expect(find.text('Jordan Lee'), findsOneWidget);
      expect(find.text('Message Coach'), findsOneWidget);
    });

    testWidgets('Feedback form validates required fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSupportRepo = MockSupportRepository(latency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportRepositoryProvider.overrideWithValue(testSupportRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FeedbackFormCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit empty form
      await tester.tap(find.widgetWithText(PrimaryButton, 'Submit Feedback'));
      await tester.pumpAndSettle();

      // Required field validation messages
      expect(find.text('Please select a category'), findsOneWidget);
      expect(find.text('Subject is required'), findsOneWidget);
      expect(find.text('Message is required'), findsOneWidget);

      // Confirmation view must NOT be displayed
      expect(find.text('Thank You for Your Feedback!'), findsNothing);
    });

    testWidgets('Submitting feedback displays confirmation view ONLY after successful submission', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSupportRepo = MockSupportRepository(latency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportRepositoryProvider.overrideWithValue(testSupportRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FeedbackFormCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select category
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Facility & Equipment').last);
      await tester.pumpAndSettle();

      // Enter subject
      final subjectField = find.byType(TextFormField).at(0);
      await tester.enterText(subjectField, 'Locker Room Cleanliness Praise');
      await tester.pumpAndSettle();

      // Enter message
      final messageField = find.byType(TextFormField).at(1);
      await tester.enterText(messageField, 'The locker rooms and sauna have been exceptionally well maintained this month!');
      await tester.pumpAndSettle();

      // Tap Submit Feedback
      await tester.tap(find.widgetWithText(PrimaryButton, 'Submit Feedback'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Confirmation view is displayed only after success!
      expect(find.text('Thank You for Your Feedback!'), findsOneWidget);
      expect(find.textContaining('Reference ID: FDB-'), findsOneWidget);
      expect(find.textContaining('Your suggestions have been recorded'), findsOneWidget);
      expect(find.text('Submit Another Feedback'), findsOneWidget);

      // Tap "Submit Another Feedback" resets the form
      await tester.tap(find.text('Submit Another Feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Thank You for Your Feedback!'), findsNothing);
      expect(find.text('Select feedback category'), findsOneWidget);
    });

    testWidgets('Report an issue flow switches categories and displays issue confirmation ticket', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testSupportRepo = MockSupportRepository(latency: Duration.zero);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supportRepositoryProvider.overrideWithValue(testSupportRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FeedbackFormCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to "Report an Issue"
      await tester.tap(find.text('Report an Issue'));
      await tester.pumpAndSettle();

      expect(find.text('Report an Issue'), findsWidgets);
      expect(find.text('Select issue category'), findsOneWidget);

      // Select issue category
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Broken/Damaged Equipment').last);
      await tester.pumpAndSettle();

      // Enter subject and message
      final subjectField = find.byType(TextFormField).at(0);
      final messageField = find.byType(TextFormField).at(1);
      await tester.enterText(subjectField, 'Cable Pulley #3 Squeaking and Sticking');
      await tester.enterText(messageField, 'The right cable on the dual adjustable pulley station has friction when pulling past 30kg.');
      await tester.pumpAndSettle();

      // Submit Issue Report
      await tester.tap(find.widgetWithText(PrimaryButton, 'Submit Issue Report'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Issue confirmation view with ticket ID
      expect(find.text('Issue Report Submitted Successfully'), findsOneWidget);
      expect(find.textContaining('Reference ID: ISS-'), findsOneWidget);
      expect(find.textContaining('Your incident ticket has been assigned to the gym facility maintenance team'), findsOneWidget);
      expect(find.text('Report Another Issue'), findsOneWidget);
    });
  });
}
