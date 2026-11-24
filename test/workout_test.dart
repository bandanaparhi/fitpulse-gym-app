import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/workouts/presentation/workout_overview_screen.dart';
import 'package:app/features/workouts/presentation/workout_details_screen.dart';
import 'package:app/features/workouts/presentation/active_workout_screen.dart';
import 'package:app/features/workouts/presentation/workout_completion_screen.dart';
import 'package:app/shared/widgets/confirmation_dialog.dart';

void main() {
  group('Workouts Feature Test Suite', () {
    testWidgets('WorkoutOverviewScreen renders assigned plan, weekly schedule, and history', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WorkoutOverviewScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('Workouts & Training'), findsOneWidget);

      // Assigned Plan Banner
      expect(find.text('CURRENT ASSIGNED PLAN'), findsOneWidget);
      expect(find.text('Hypertrophy & Functional Conditioning'), findsOneWidget);
      expect(find.text('Coach Jordan Lee'), findsOneWidget);
      expect(find.text('4 Days / Week'), findsOneWidget);

      // Assigned Routines
      expect(find.text('Upper Body Power & Hypertrophy'), findsWidgets);
      expect(find.text('Lower Body Strength & Core'), findsWidgets);
      expect(find.text('60 min'), findsWidgets);
      expect(find.text('55 min'), findsWidgets);

      // Weekly Schedule (Training Days vs Rest Days)
      expect(find.text('Weekly Workout Schedule'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('TRAINING'), findsWidgets);
      expect(find.text('REST'), findsWidgets);

      // Completed Workouts History
      expect(find.text('Completed Workouts & History'), findsOneWidget);
      expect(find.textContaining('Completed'), findsWidgets);
    });

    testWidgets('WorkoutDetailsScreen renders exercise breakdown, sets/reps, and instructions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WorkoutDetailsScreen(workoutId: 'WK-01'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Header Meta
      expect(find.text('Upper Body Power & Hypertrophy'), findsWidgets);
      expect(find.text('STRENGTH'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('60 mins'), findsOneWidget);

      // Exercise List
      expect(find.text('Barbell Incline Bench Press'), findsOneWidget);
      expect(find.text('Weighted Pull-Ups'), findsOneWidget);
      expect(find.text('Standing Overhead Barbell Press'), findsOneWidget);

      // Sets & Reps, Weight, Rest
      expect(find.text('4 Sets × 8 Reps'), findsOneWidget);
      expect(find.text('75.0 kg'), findsOneWidget);
      expect(find.text('90s rest'), findsWidgets);

      // Instructions
      expect(find.text('Exercise Instructions:'), findsWidgets);
      expect(find.textContaining('Set incline bench to 30°'), findsOneWidget);

      // CTA
      expect(find.text('Start Live Workout'), findsOneWidget);
    });

    testWidgets('ActiveWorkoutScreen tracks sets, supports navigation, and confirms completion', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ActiveWorkoutScreen(workoutId: 'WK-01'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Current Exercise & Set
      expect(find.text('Barbell Incline Bench Press'), findsWidgets);
      expect(find.text('Set 1 of 4'), findsOneWidget);
      expect(find.text('Mark Set 1 Complete'), findsOneWidget);

      // Tap Mark Set 1 Complete -> advances to Set 2 and shows rest timer
      await tester.tap(find.text('Mark Set 1 Complete'));
      await tester.pump();

      expect(find.text('Rest Time Remaining'), findsOneWidget);
      expect(find.text('Skip Rest'), findsOneWidget);

      // Skip rest timer
      await tester.tap(find.text('Skip Rest'));
      await tester.pump();

      // Check next exercise navigation button
      expect(find.text('Next Ex'), findsOneWidget);
      await tester.tap(find.text('Next Ex'));
      await tester.pump();

      // Should now be on Weighted Pull-Ups
      expect(find.text('Weighted Pull-Ups'), findsWidgets);

      // Check previous exercise navigation
      expect(find.text('Previous Ex'), findsOneWidget);
      await tester.tap(find.text('Previous Ex'));
      await tester.pump();

      expect(find.text('Barbell Incline Bench Press'), findsWidgets);

      // Tap Finish Workout button
      final finishButton = find.text('Finish Workout');
      await tester.ensureVisible(finishButton);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear before completing
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(find.text('Complete Workout?'), findsOneWidget);

      // Cancel / Resume workout first
      await tester.tap(find.text('Resume Workout'));
      await tester.pumpAndSettle();

      // Ensure dialog dismissed and workout is still active
      expect(find.byType(ConfirmationDialog), findsNothing);
      expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
      expect(find.byType(WorkoutCompletionScreen), findsNothing);

      // Tap Finish Workout again and confirm
      await tester.ensureVisible(finishButton);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm & Complete'));
      await tester.pumpAndSettle();

      // Now WorkoutCompletionScreen must be displayed
      expect(find.byType(WorkoutCompletionScreen), findsOneWidget);
      expect(find.text('Workout Completed!'), findsOneWidget);
      expect(find.text('Upper Body Power & Hypertrophy'), findsWidgets);
      expect(find.text('Back to Dashboard'), findsOneWidget);
      expect(find.text('View Workouts'), findsOneWidget);
    });
  });
}
