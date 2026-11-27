import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/diet/presentation/diet_plan_screen.dart';
import 'package:app/app/providers.dart';
import 'package:app/data/models/diet_plan.dart';

void main() {
  group('Diet Plan Feature Test Suite', () {
    testWidgets('DietPlanScreen renders plan details, macros, meals, and trainer notes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DietPlanScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('Diet & Nutrition Plan'), findsOneWidget);

      // Plan Name & Assigned Professional
      expect(find.text('Lean Muscle & Metabolic Optimization'), findsOneWidget);
      expect(find.text('Coach Jordan Lee, CSCS'), findsOneWidget);
      expect(find.text('Goal: Muscle Gain & Leanness'), findsOneWidget);

      // Calorie & Macro Targets
      expect(find.text('Daily Calorie & Macro Targets'), findsOneWidget);
      expect(find.textContaining('2650 kcal'), findsWidgets);
      expect(find.text('180g'), findsWidgets);
      expect(find.text('280g'), findsWidgets);
      expect(find.text('75g'), findsWidgets);
      expect(find.textContaining('3.5 - 4.0 Litres'), findsOneWidget);

      // Meals in Schedule
      expect(find.text('Daily Meal Schedule'), findsOneWidget);
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Mid-Morning Snack'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Pre-Workout Snack'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);

      // Food items & portion sizes
      expect(find.text('Large Pasture-Raised Whole Eggs'), findsOneWidget);
      expect(find.text('Portion: 4 whole eggs (200g)'), findsOneWidget);
      expect(find.text('Grilled Skinless Chicken Breast'), findsOneWidget);
      expect(find.text('Portion: 200g (cooked weight)'), findsOneWidget);

      // Trainer's meal notes
      expect(find.textContaining('Trainer\'s Note for this Meal:'), findsWidgets);

      // Non-prescriptive read-only disclaimer
      expect(
        find.text('Assigned Nutrition Guidance — Strictly Read Only'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Supplements and medical diets are not prescribed'),
        findsOneWidget,
      );
    });

    testWidgets('Switching days updates active meal protocol and calories', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DietPlanScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Initially on Training Day
      expect(find.text('Training Day (Mon, Thu, Fri)'), findsOneWidget);
      expect(find.text('Recovery Day (Wed, Sun)'), findsOneWidget);

      // Tap Recovery Day tab
      await tester.tap(find.text('Recovery Day (Wed, Sun)'));
      await tester.pumpAndSettle();

      // Calorie target for recovery day is 2350 kcal
      expect(find.textContaining('2350 kcal'), findsWidgets);
      // Food item from recovery day appears
      expect(find.text('Whole Eggs with Egg Whites Scramble'), findsOneWidget);
      expect(find.text('Hass Avocado Slices'), findsOneWidget);
    });

    testWidgets('Empty state is displayed with Contact Trainer CTA when no diet plan is assigned', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dietPlanProvider.overrideWith((ref) => Future<DietPlan?>.value(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DietPlanScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify Empty State
      expect(find.text('No Diet Plan Assigned'), findsOneWidget);
      expect(
        find.textContaining('Reach out to Coach Jordan Lee to create a personalized meal plan'),
        findsOneWidget,
      );
      expect(find.text('Contact Trainer'), findsOneWidget);
    });

    testWidgets('Daily calorie/macro tracker, food logging, and meal reminders work on DietPlanScreen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DietPlanScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Daily Calorie & Macro Tracker
      expect(find.text('Daily Calorie & Macro Tracker'), findsOneWidget);
      expect(find.text('Daily Calorie Intake'), findsOneWidget);
      expect(find.text('0 / 2650 kcal'), findsOneWidget);
      expect(find.text('Log Food'), findsOneWidget);

      // Meal Reminders
      expect(find.text('Meal Reminders'), findsOneWidget);
      expect(find.textContaining('Breakfast:'), findsOneWidget);
      expect(find.textContaining('Lunch:'), findsOneWidget);
      expect(find.textContaining('Dinner:'), findsOneWidget);

      // Quick-log first meal (Breakfast)
      final logMealBtn = find.text('Log Meal').first;
      await tester.ensureVisible(logMealBtn);
      await tester.tap(logMealBtn);
      await tester.pumpAndSettle();

      expect(find.text('Today\'s Food Log (1)'), findsOneWidget);
      expect(find.text('0 / 2650 kcal'), findsNothing);
    });
  });
}
