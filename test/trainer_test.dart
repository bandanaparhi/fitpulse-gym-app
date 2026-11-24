import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/trainer/presentation/trainer_screen.dart';
import 'package:app/app/providers.dart';

void main() {
  group('My Trainer Feature Test Suite', () {
    testWidgets('TrainerScreen renders trainer profile, qualifications, specializations, contact details, sessions, and workouts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TrainerScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title & Subtitle
      expect(find.text('My Trainer & Coaching'), findsOneWidget);
      expect(find.textContaining('Connect with your assigned fitness coach'), findsOneWidget);

      // Trainer Name & Avatar
      expect(find.text('Jordan Lee'), findsWidgets);
      expect(find.text('JL'), findsOneWidget);
      expect(find.text('Dedicated Personal Fitness Coach'), findsOneWidget);

      // Rating & Clients
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('42 Active Clients'), findsOneWidget);

      // Specialty & Bio
      expect(find.textContaining('Hypertrophy & Functional Conditioning'), findsWidgets);
      expect(find.textContaining('Certified CSCS coach with 8+ years experience'), findsOneWidget);

      // Qualifications
      expect(find.text('Qualifications & Certifications'), findsOneWidget);
      expect(find.text('CSCS (Certified Strength & Conditioning Specialist)'), findsOneWidget);
      expect(find.text('USAW Level 2 Olympic Weightlifting Coach'), findsOneWidget);

      // Specializations
      expect(find.text('Specializations & Focus Areas'), findsOneWidget);
      expect(find.text('Hypertrophy & Lean Muscle Gain'), findsOneWidget);
      expect(find.text('Functional Conditioning & Mobility'), findsOneWidget);

      // Contact Information
      expect(find.text('Trainer Contact Details'), findsOneWidget);
      expect(find.text('+91 98112 34567'), findsOneWidget);
      expect(find.text('jordan.lee@fitpulse.com'), findsOneWidget);

      // Upcoming Coaching Sessions
      expect(find.textContaining('Upcoming Coaching Sessions'), findsOneWidget);
      expect(find.text('1-on-1 Strength & Technique Coaching'), findsOneWidget);
      expect(find.textContaining('Olympic Lifting Platform 2'), findsOneWidget);
      expect(find.textContaining('60 min'), findsWidgets);

      // Assigned Workout Plans
      expect(find.textContaining('Assigned Workout Plans'), findsOneWidget);
      expect(find.text('Upper Body Power & Hypertrophy'), findsOneWidget);
      expect(find.text('Lower Body Strength & Core'), findsOneWidget);
    });

    testWidgets('Contact Trainer dialog opens and sends in-app message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TrainerScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap Contact Button
      final contactBtn = find.text('Contact Coach Jordan');
      expect(contactBtn, findsOneWidget);
      await tester.ensureVisible(contactBtn);
      await tester.pumpAndSettle();
      await tester.tap(contactBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Contact Coach Jordan Lee'), findsOneWidget);
      expect(find.text('Direct Contact Methods'), findsOneWidget);
      expect(find.text('Phone / WhatsApp'), findsOneWidget);
      expect(find.text('+91 98112 34567'), findsWidgets);
      expect(find.text('Official Email'), findsOneWidget);
      expect(find.text('jordan.lee@fitpulse.com'), findsWidgets);

      // Enter in-app message
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'Hi Coach, can we review my back squat technique tomorrow?');
      await tester.pumpAndSettle();

      // Tap "Send Message"
      final sendBtn = find.text('Send Message');
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Dialog closed and confirmation snackbar shown
      expect(find.textContaining('Message sent to Coach Jordan Lee!'), findsOneWidget);
    });

    testWidgets('Upcoming session cancellation shows confirmation dialog and updates state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TrainerScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Locate Cancel Session button on upcoming session
      final cancelBtn = find.widgetWithText(OutlinedButton, 'Cancel Session').first;
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Cancel Coaching Session'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to cancel your upcoming 1-on-1 session'), findsOneWidget);

      // Confirm cancellation
      final confirmBtn = find.text('Yes, Cancel Session');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Session cancelled snackbar appears
      expect(find.textContaining('has been cancelled.'), findsOneWidget);
    });

    testWidgets('Displays friendly empty state when no trainer is assigned', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignedTrainerProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TrainerScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Empty State
      expect(find.text('No Trainer Assigned'), findsOneWidget);
      expect(find.textContaining('Please speak with gym administration or front desk staff'), findsOneWidget);
      expect(find.text('Contact Gym Staff'), findsOneWidget);
    });
  });
}
