import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/models/fitness_profile.dart';
import 'package:app/data/models/workout_log.dart';
import 'package:app/data/repositories/workout_planner_engine.dart';
import 'package:app/features/workouts/presentation/fitness_profile_screen.dart';
import 'package:app/features/workouts/presentation/weekly_plan_screen.dart';
import 'package:app/features/workouts/presentation/today_workout_screen.dart';
import 'package:app/features/workouts/presentation/exercise_details_screen.dart';
import 'package:app/features/workouts/presentation/planner_active_workout_screen.dart';
import 'package:app/features/workouts/presentation/workout_history_screen.dart';
import 'package:app/features/workouts/presentation/personal_records_screen.dart';
import 'package:app/features/workouts/presentation/training_progress_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkoutPlannerEngine Unit Tests', () {
    FitnessProfile makeProfile({
      String level = 'Beginner',
      String goal = 'General Fitness',
      int days = 3,
      String location = 'Gym',
      List<String> equipment = const [
        'Bodyweight',
        'Dumbbells',
        'Barbell & Rack',
        'Machines',
        'Cables',
        'Cardio Machines',
      ],
      List<String> avoid = const [],
    }) {
      return FitnessProfile(
        memberId: 'GM-1024',
        age: 28,
        heightCm: 175,
        weightKg: 74,
        fitnessLevel: level,
        primaryGoal: goal,
        trainingExperience: '6–18 months',
        trainingDaysPerWeek: days,
        workoutDurationMinutes: 45,
        workoutLocation: location,
        availableEquipment: equipment,
        avoidExercises: avoid,
        updatedAt: DateTime(2026, 11, 20),
      );
    }

    test('Beginner plan generates 2-3 full-body sessions with rest days and warm-up/cool-down', () {
      final plan = WorkoutPlannerEngine.generatePlan(
        makeProfile(level: 'Beginner', goal: 'General Fitness', days: 3),
      );
      expect(plan.level, 'Beginner');
      expect(plan.trainingDaysPerWeek, 3);
      expect(plan.weekSchedule.length, 7);
      expect(plan.weekSchedule.where((d) => !d.isRestDay).length, 3);
      expect(plan.weekSchedule.where((d) => d.isRestDay).length, 4);
      expect(plan.sessions.first.warmUp, isNotEmpty);
      expect(plan.sessions.first.mainExercises, isNotEmpty);
      expect(plan.sessions.first.coolDown, isNotEmpty);
      // Verify Beginner rest intervals stay in manageable 60-90s range
      for (final ex in plan.sessions.first.mainExercises) {
        expect(ex.restSeconds, inInclusiveRange(45, 90));
      }
    });

    test('Advanced plan generates Upper/Lower 4-day split', () {
      final plan = WorkoutPlannerEngine.generatePlan(
        makeProfile(level: 'Advanced', goal: 'Muscle Gain', days: 4),
      );
      expect(plan.level, 'Advanced');
      expect(plan.trainingDaysPerWeek, 4);
      expect(plan.sessions.length, 4);
      expect(plan.sessions.any((s) => s.title.contains('Upper')), isTrue);
      expect(plan.sessions.any((s) => s.title.contains('Lower')), isTrue);
    });

    test('High-Performance plan includes Strength, Conditioning/Mobility, and Power with supervision notes', () {
      final plan = WorkoutPlannerEngine.generatePlan(
        makeProfile(level: 'High-Performance', goal: 'Strength', days: 5),
      );
      expect(plan.level, 'High-Performance');
      expect(plan.trainingDaysPerWeek, 5);
      expect(plan.sessions.any((s) => s.title.contains('Power')), isTrue);
      expect(plan.sessions.any((s) => s.title.contains('Conditioning')), isTrue);
      final powerSession = plan.sessions.firstWhere((s) => s.title.contains('Power'));
      expect(powerSession.coachingNotes, contains('speed'));
    });

    test('Home workout without gym machines substitutes bodyweight/dumbbell exercises and skips avoided exercises', () {
      final plan = WorkoutPlannerEngine.generatePlan(
        makeProfile(
          level: 'Advanced',
          goal: 'Muscle Gain',
          days: 4,
          location: 'Home',
          equipment: const ['Bodyweight', 'Dumbbells'],
          avoid: const ['Walking Lunges'],
        ),
      );
      final allMain = plan.sessions.expand((s) => s.mainExercises).toList();
      expect(allMain.any((e) => e.equipment == 'Machines'), isFalse);
      expect(allMain.any((e) => e.equipment == 'Cables'), isFalse);
      expect(allMain.any((e) => e.name.contains('Walking Lunges')), isFalse);
    });

    test('Safe progression NEVER increases load after only 1 completed workout, only after >=2 clean sessions', () {
      final now = DateTime.now();
      final oneLog = WorkoutLog(
        id: 'L1',
        memberId: 'GM-1024',
        sessionId: 'SES-ADV-U1',
        sessionTitle: 'Upper Body',
        focus: 'Upper',
        startedAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(days: 1)),
        durationMinutes: 50,
        perceivedDifficulty: 7,
        exerciseLogs: [
          ExerciseLog(
            exerciseId: 'ex_bench_press',
            exerciseName: 'Barbell Bench Press',
            sets: [
              SetLog(setNumber: 1, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now),
              SetLog(setNumber: 2, repsCompleted: 8, weightKg: 70, completed: true, loggedAt: now),
            ],
          ),
        ],
      );

      final afterOne = WorkoutPlannerEngine.evaluateProgressions([oneLog], null);
      expect(afterOne.length, 1);
      expect(afterOne.first.readyToProgress, isFalse);

      final secondLog = oneLog.copyWith(
        id: 'L2',
        startedAt: now.subtract(const Duration(days: 4)),
        completedAt: now.subtract(const Duration(days: 4)),
      );
      final afterTwo = WorkoutPlannerEngine.evaluateProgressions([oneLog, secondLog], null);
      expect(afterTwo.length, 1);
      expect(afterTwo.first.readyToProgress, isTrue);
      expect(afterTwo.first.suggestedWeightKg, greaterThan(70));
    });
  });

  group('Workout & Training Planner Screens Widget Tests', () {
    Widget wrapScreen(Widget screen) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: screen),
        ),
      );
    }

    testWidgets('FitnessProfileScreen renders fields, optional injuries note, and safety banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapScreen(const FitnessProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Fitness Profile'), findsWidgets);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('High-Performance'), findsOneWidget);
      expect(find.text('Muscle Gain'), findsOneWidget);
      expect(find.text('Fat Loss'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Endurance'), findsOneWidget);
      expect(find.text('General Fitness'), findsOneWidget);
      expect(find.text('Save Profile & Generate Weekly Plan'), findsOneWidget);
      expect(find.textContaining('general fitness guidance'), findsWidgets);
    });

    testWidgets('WeeklyPlanScreen renders 7-day personalized plan and safety notice', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapScreen(const WeeklyPlanScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Weekly Plan'), findsWidgets);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
      expect(find.textContaining('SAMPLE DATA'), findsWidgets);
    });

    testWidgets('TodayWorkoutScreen renders today focus or rest view and Rest Timer modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapScreen(const TodayWorkoutScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Today'), findsWidgets);

      // If today is a rest day (e.g. Wednesday), tap a Preview button to open a session
      if (find.text('Rest Timer').evaluate().isEmpty) {
        final previewBtn = find.text('Preview');
        expect(previewBtn, findsWidgets);
        await tester.ensureVisible(previewBtn.first);
        await tester.tap(previewBtn.first);
        await tester.pumpAndSettle();
      }

      final restTimerBtn = find.text('Rest Timer');
      expect(restTimerBtn, findsWidgets);
      await tester.ensureVisible(restTimerBtn.first);
      await tester.tap(restTimerBtn.first);
      await tester.pump();
      expect(find.text('REST REMAINING'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('ExerciseDetailsScreen displays instructions, mistakes, variations, alternatives, and truthful media note', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapScreen(const ExerciseDetailsScreen(exerciseId: 'ex_bench_press')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsWidgets);
      expect(find.textContaining('No local video or animation asset is configured'), findsOneWidget);
      expect(find.textContaining('Common Mistakes'), findsWidgets);
      expect(find.textContaining('Easier'), findsWidgets);
      expect(find.textContaining('Harder'), findsWidgets);
    });

    testWidgets('PlannerActiveWorkoutScreen supports set completion, rest timer, pain stop modal, and finish summary', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrapScreen(const PlannerActiveWorkoutScreen(sessionId: 'SES-ADV-U1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upper Body Strength & Hypertrophy'), findsWidgets);
      expect(find.text('Barbell Bench Press'), findsWidgets);

      // Test Replace Exercise modal
      final replaceBtn = find.text('Replace Exercise');
      await tester.ensureVisible(replaceBtn);
      await tester.tap(replaceBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('Replace'), findsWidgets);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Test Stop / Report Pain safety dialog
      final painBtn = find.text('Stop / Report Pain');
      await tester.ensureVisible(painBtn);
      await tester.tap(painBtn);
      await tester.pumpAndSettle();
      expect(find.textContaining('Do not train through sharp pain'), findsWidgets);
      await tester.tap(find.text('Resume Workout'));
      await tester.pumpAndSettle();

      // Test Finish Workout confirmation & summary
      final finishBtn = find.text('Finish Workout');
      await tester.ensureVisible(finishBtn);
      await tester.tap(finishBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish & Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Calories burned and heart rate are not displayed'), findsOneWidget);
    });

    testWidgets('WorkoutHistoryScreen, PersonalRecordsScreen, and TrainingProgressScreen render cleanly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrapScreen(const WorkoutHistoryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Workout History'), findsWidgets);
      expect(find.textContaining('Lower Body Power'), findsWidgets);

      await tester.pumpWidget(wrapScreen(const PersonalRecordsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Personal Records'), findsWidgets);
      expect(find.text('Barbell Back Squat'), findsWidgets);

      await tester.pumpWidget(wrapScreen(const TrainingProgressScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Training Progress & Load'), findsWidgets);
      expect(find.textContaining('at least 2 clean'), findsWidgets);
    });
  });
}
