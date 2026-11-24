import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:app/features/progress/presentation/progress_screen.dart';
import 'package:app/features/progress/presentation/widgets/add_edit_measurement_modal.dart';
import 'package:app/features/progress/presentation/widgets/create_fitness_goal_modal.dart';
import 'package:app/shared/widgets/confirmation_dialog.dart';

void main() {
  group('Fitness Progress Feature Test Suite', () {
    testWidgets('ProgressScreen renders summary cards, charts, goals, and measurements log', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('Fitness Progress & Analytics'), findsOneWidget);

      // KPI Summaries
      expect(find.text('Current Weight'), findsOneWidget);
      expect(find.text('78.4 kg'), findsWidgets);
      expect(find.text('Body Fat Percentage'), findsOneWidget);
      expect(find.text('14.2%'), findsWidgets);
      expect(find.text('Workouts Completed'), findsOneWidget);
      expect(find.text('Monthly Attendance'), findsOneWidget);

      // Chart Card
      expect(find.text('Body Weight Progression'), findsOneWidget);
      expect(find.text('Weight'), findsWidgets);
      expect(find.text('Body Fat %'), findsWidgets);
      expect(find.text('Waist'), findsWidgets);
      expect(find.text('Muscle Mass'), findsWidgets);

      // Personal Fitness Goals
      expect(find.text('Personal Fitness Goals'), findsOneWidget);
      expect(find.text('Target Body Weight'), findsWidgets);
      expect(find.text('Target Body Fat'), findsWidgets);
      expect(find.text('Set Goal'), findsOneWidget);

      // Measurements Log
      expect(find.text('Body Measurements Log'), findsOneWidget);
      expect(find.text('Log Entry'), findsOneWidget);
      expect(find.text('Metric (kg, cm)'), findsOneWidget);

      // Non-Diagnostic Medical Disclaimer
      expect(find.text('General Wellness Notice'), findsOneWidget);
      expect(
        find.textContaining('do not constitute clinical evaluations'),
        findsOneWidget,
      );
    });

    testWidgets('Unit toggle switches between Metric (kg, cm) and Imperial (lb, in)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Initially in Metric
      expect(find.text('78.4 kg'), findsWidgets);
      expect(find.text('Metric (kg, cm)'), findsOneWidget);

      // Tap toggle to Imperial
      final toggleButton = find.text('Metric (kg, cm)');
      await tester.ensureVisible(toggleButton);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Now in Imperial
      expect(find.text('Imperial (lb, in)'), findsOneWidget);
      expect(find.text('172.8 lb'), findsWidgets);

      // Toggle back to Metric
      await tester.tap(find.text('Imperial (lb, in)'));
      await tester.pumpAndSettle();

      expect(find.text('Metric (kg, cm)'), findsOneWidget);
      expect(find.text('78.4 kg'), findsWidgets);
    });

    testWidgets('Adding a new measurement logs it into the measurements list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap Log Entry
      final logEntryButton = find.text('Log Entry');
      await tester.ensureVisible(logEntryButton);
      await tester.tap(logEntryButton);
      await tester.pumpAndSettle();

      // Modal appears
      expect(find.byType(AddEditMeasurementModal), findsOneWidget);
      expect(find.text('Add Measurement'), findsOneWidget);

      // Enter value
      final valueField = find.byType(TextFormField).first;
      await tester.enterText(valueField, '77.8');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Save Measurement'));
      await tester.pumpAndSettle();

      // Modal closed and entry logged
      expect(find.byType(AddEditMeasurementModal), findsNothing);
      expect(find.text('77.8 kg'), findsWidgets);
    });

    testWidgets('Deleting a measurement triggers confirmation dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Find delete button
      final deleteButtons = find.byTooltip('Delete Measurement');
      expect(deleteButtons, findsWidgets);

      await tester.ensureVisible(deleteButtons.first);
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(find.text('Delete Measurement?'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmationDialog), findsNothing);
    });

    testWidgets('Creating personal fitness goal adds it to goals list', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap Set Goal
      final setGoalButton = find.text('Set Goal');
      await tester.ensureVisible(setGoalButton);
      await tester.tap(setGoalButton);
      await tester.pumpAndSettle();

      // Modal appears
      expect(find.byType(CreateFitnessGoalModal), findsOneWidget);
      expect(find.text('Create Fitness Goal'), findsOneWidget);

      // Submit default goal
      await tester.tap(find.text('Set Goal').last);
      await tester.pumpAndSettle();

      expect(find.byType(CreateFitnessGoalModal), findsNothing);
      expect(find.text('Personal Fitness Goals'), findsOneWidget);
    });
  });
}
