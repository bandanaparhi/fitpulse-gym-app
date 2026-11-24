import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/diet_plan.dart';

/// Card showing daily calories and macronutrient targets.
class MacroTargetsCard extends StatelessWidget {
  final DietPlan plan;
  final int activeCalories;
  final int activeProtein;
  final int activeCarbs;
  final int activeFat;

  const MacroTargetsCard({
    super.key,
    required this.plan,
    required this.activeCalories,
    required this.activeProtein,
    required this.activeCarbs,
    required this.activeFat,
  });

  @override
  Widget build(BuildContext context) {
    // Total macro calories
    final proteinKcal = activeProtein * 4;
    final carbsKcal = activeCarbs * 4;
    final fatKcal = activeFat * 9;
    final totalKcal = (proteinKcal + carbsKcal + fatKcal).toDouble();

    final proteinRatio = totalKcal > 0 ? proteinKcal / totalKcal : 0.27;
    final carbsRatio = totalKcal > 0 ? carbsKcal / totalKcal : 0.42;
    final fatRatio = totalKcal > 0 ? fatKcal / totalKcal : 0.25;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Daily Calorie & Macro Targets',
                        style: AppTextStyles.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$activeCalories kcal / day',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.limeAccentDark,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Macro Breakdown Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (proteinRatio * 100).toInt(),
                    child: Container(color: AppColors.limeAccentDark),
                  ),
                  Expanded(
                    flex: (carbsRatio * 100).toInt(),
                    child: Container(color: AppColors.info),
                  ),
                  Expanded(
                    flex: (fatRatio * 100).toInt(),
                    child: Container(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Macro Stats Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 600;

              final proteinTile = _buildMacroTile(
                label: 'Protein',
                amount: '${activeProtein}g',
                percent: '${(proteinRatio * 100).toInt()}%',
                calories: '$proteinKcal kcal',
                color: AppColors.limeAccentDark,
              );

              final carbsTile = _buildMacroTile(
                label: 'Carbohydrates',
                amount: '${activeCarbs}g',
                percent: '${(carbsRatio * 100).toInt()}%',
                calories: '$carbsKcal kcal',
                color: AppColors.info,
              );

              final fatsTile = _buildMacroTile(
                label: 'Healthy Fats',
                amount: '${activeFat}g',
                percent: '${(fatRatio * 100).toInt()}%',
                calories: '$fatKcal kcal',
                color: AppColors.warning,
              );

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(child: proteinTile),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: carbsTile),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: fatsTile),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: proteinTile),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: carbsTile),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    fatsTile,
                  ],
                );
              }
            },
          ),

          if (plan.hydrationRecommendation != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  size: 16,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Hydration Target: ',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Flexible(
                  child: Text(
                    plan.hydrationRecommendation!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroTile({
    required String label,
    required String amount,
    required String percent,
    required String calories,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                percent,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            calories,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
