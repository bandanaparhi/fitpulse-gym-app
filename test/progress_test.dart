import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/app/providers.dart';
import 'package:app/core/utils/image_file_picker.dart';
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

    testWidgets('BMI & BMR calculator and daily steps, calories, water, and sleep trackers update live', (tester) async {
      SharedPreferences.setMockInitialValues({});
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

      await tester.pumpAndSettle();

      // Daily Activity, Water & Sleep Trackers
      expect(find.text('Daily Activity, Water & Sleep'), findsOneWidget);
      expect(find.text('Step Counts'), findsOneWidget);
      expect(find.text('Calories Burned'), findsOneWidget);
      expect(find.text('Water Intake Tracker'), findsOneWidget);
      expect(find.text('Sleep Tracking'), findsOneWidget);

      await tester.tap(find.text('+1,000'));
      await tester.pumpAndSettle();
      expect(find.text('1000 / 8000'), findsOneWidget);

      await tester.tap(find.text('+150'));
      await tester.pumpAndSettle();
      expect(find.text('150 / 500'), findsOneWidget);

      await tester.tap(find.text('+500 ml'));
      await tester.pumpAndSettle();
      expect(find.text('0.50 / 3.0 L'), findsOneWidget);

      await tester.tap(find.text('+1h'));
      await tester.pumpAndSettle();
      expect(find.text('1.0 / 8 hrs'), findsOneWidget);

      // BMI & BMR Calculator
      expect(find.text('BMI & BMR Calculator'), findsOneWidget);
      expect(find.text('BMI Result'), findsOneWidget);
      expect(find.text('BMR Result (Resting Energy)'), findsOneWidget);
      expect(find.textContaining('kcal/day'), findsWidgets);
    });

    testWidgets(
      'Muscle growth, before/after photos, personal records, weekly/monthly reports, and goal compilation work on ProgressScreen',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.binding.setSurfaceSize(const Size(1200, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Minimal valid 1x1 transparent PNG bytes
        final samplePng = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
        );
        int pickCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              progressPhotoPickerProvider.overrideWithValue(() async {
                pickCount++;
                return PickedImageFile(
                  fileName: pickCount == 1 ? 'before.png' : 'after.png',
                  bytes: samplePng,
                );
              }),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ProgressScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Muscle Growth Tracking
        expect(find.text('Muscle Growth Tracking'), findsOneWidget);
        expect(find.text('Skeletal Muscle Mass'), findsOneWidget);
        expect(find.text('64.1 kg'), findsWidgets);
        expect(find.text('+1.7 kg since initial'), findsOneWidget);
        expect(find.text('104.0 cm'), findsWidgets);

        // 2. Before & After Progress Photos
        expect(find.text('Before & After Progress Photos'), findsOneWidget);
        expect(find.text('No Before Photo Yet'), findsOneWidget);
        expect(find.text('No After Photo Yet'), findsOneWidget);

        final uploadBefore = find.text('Upload Before Photo');
        await tester.ensureVisible(uploadBefore);
        await tester.tap(uploadBefore);
        await tester.pumpAndSettle();
        expect(find.text('Save Before Photo'), findsOneWidget);
        await tester.tap(find.text('Save Photo'));
        await tester.pumpAndSettle();
        expect(find.text('No Before Photo Yet'), findsNothing);

        final uploadAfter = find.text('Upload After Photo');
        await tester.ensureVisible(uploadAfter);
        await tester.tap(uploadAfter);
        await tester.pumpAndSettle();
        expect(find.text('Save After Photo'), findsOneWidget);
        await tester.tap(find.text('Save Photo'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Comparison:'), findsOneWidget);

        // 3. Personal Fitness Records
        expect(find.text('Personal Fitness Records'), findsOneWidget);
        expect(find.text('Log PR'), findsOneWidget);
        expect(find.text('All PRs'), findsOneWidget);

        // 4. Weekly & Monthly Reports
        expect(find.text('Weekly & Monthly Reports'), findsOneWidget);
        expect(find.text('Workouts (7 Days)'), findsOneWidget);
        final monthlyBtn = find.text('Monthly Report');
        await tester.ensureVisible(monthlyBtn);
        await tester.tap(monthlyBtn);
        await tester.pumpAndSettle();
        expect(find.text('Workouts (30 Days)'), findsOneWidget);

        // 5. Fitness Goal Compilation & Completion toggle
        expect(find.text('Fitness Goal Compilation'), findsOneWidget);
        expect(find.text('Completed: 0'), findsOneWidget);
        final markAchieved = find.text('Mark Achieved').first;
        await tester.ensureVisible(markAchieved);
        await tester.tap(markAchieved);
        await tester.pumpAndSettle();
        expect(find.text('Completed: 1'), findsOneWidget);
        expect(find.text('Achieved'), findsOneWidget);
      },
    );
  });
}
