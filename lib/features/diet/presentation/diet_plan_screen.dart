import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/day_selector_tabs.dart';
import 'widgets/diet_plan_header_card.dart';
import 'widgets/macro_targets_card.dart';
import 'widgets/meal_card.dart';

/// Diet Plan screen at `/diet-plan`.
///
/// Features:
/// - Displays assigned plan, coach name, start & update dates
/// - Daily calorie targets and macronutrient ratio breakdown
/// - Multi-day schedule switching
/// - Full meal schedule (Breakfast, snacks, Lunch, Dinner)
/// - Exact food items, portion sizes, calories, and macros
/// - Trainer's personalized meal notes
/// - Friendly empty state with "Contact Trainer" CTA when unassigned
/// - Strictly read-only; non-prescriptive and non-medical
class DietPlanScreen extends ConsumerStatefulWidget {
  const DietPlanScreen({super.key});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(currentMemberProvider);
    final dietPlanAsync = ref.watch(dietPlanProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading nutrition plan...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Diet Plan',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(currentMemberProvider);
            ref.invalidate(dietPlanProvider);
          },
        ),
      ),
      data: (member) {
        return dietPlanAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: LoadingIndicator(message: 'Loading assigned meal plan...'),
          ),
          error: (err, _) => Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            body: ErrorState(
              title: 'Unable to Load Meal Plan',
              message: err.toString(),
              onRetry: () => ref.invalidate(dietPlanProvider),
            ),
          ),
          data: (plan) {
            if (plan == null) {
              return Scaffold(
                backgroundColor: AppColors.scaffoldBackground,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'No Diet Plan Assigned',
                      message:
                          'You do not have an active diet or nutrition plan assigned yet. Reach out to Coach ${member.assignedTrainer} to create a personalized meal plan.',
                      actionLabel: 'Contact Trainer',
                      onAction: () => context.go('/trainer'),
                    ),
                  ),
                ),
              );
            }

            final days = plan.days;
            final activeDay = (days.isNotEmpty && _selectedDayIndex < days.length)
                ? days[_selectedDayIndex]
                : null;

            final activeCalories =
                activeDay?.dayCalorieTarget ?? plan.dailyCalorieTarget;
            final activeProtein =
                activeDay?.dayProteinGrams ?? plan.proteinGrams;
            final activeCarbs = activeDay?.dayCarbsGrams ?? plan.carbsGrams;
            final activeFat = activeDay?.dayFatGrams ?? plan.fatGrams;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  const PageHeader(
                    title: 'Diet & Nutrition Plan',
                    subtitle:
                        'Review your daily meal protocol, macronutrient targets, portion sizes, and coach notes.',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 1. Plan Overview Card
                  DietPlanHeaderCard(plan: plan),

                  const SizedBox(height: AppSpacing.xl),

                  // 2. Macronutrient Targets Card
                  MacroTargetsCard(
                    plan: plan,
                    activeCalories: activeCalories,
                    activeProtein: activeProtein,
                    activeCarbs: activeCarbs,
                    activeFat: activeFat,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3. Multi-Day Selector Tabs
                  if (days.isNotEmpty) ...[
                    DaySelectorTabs(
                      days: days,
                      selectedIndex: _selectedDayIndex,
                      onDaySelected: (idx) {
                        setState(() => _selectedDayIndex = idx);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // 4. Daily Meal Schedule
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: AppColors.darkCharcoal,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            'Daily Meal Schedule',
                            style: AppTextStyles.h3,
                          ),
                        ],
                      ),
                      if (activeDay != null)
                        Text(
                          '${activeDay.meals.length} Scheduled Meals',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Meal Cards List
                  if (activeDay != null && activeDay.meals.isNotEmpty)
                    Column(
                      children: List.generate(activeDay.meals.length, (idx) {
                        return MealCard(
                          meal: activeDay.meals[idx],
                          index: idx + 1,
                        );
                      }),
                    )
                  else
                    ...plan.mealSummaries.map((summary) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          summary,
                          style: AppTextStyles.bodyMedium,
                        ),
                      );
                    }),

                  const SizedBox(height: AppSpacing.xl),

                  // 5. Read-Only Dietary Disclaimer
                  _buildDietaryDisclaimer(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDietaryDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Nutrition Guidance — Strictly Read Only',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This diet plan is provided by your fitness coach for athletic fueling and healthy habit guidance. It is strictly read-only and does not constitute medical nutrition therapy or clinical dietary treatment. Supplements and medical diets are not prescribed.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
