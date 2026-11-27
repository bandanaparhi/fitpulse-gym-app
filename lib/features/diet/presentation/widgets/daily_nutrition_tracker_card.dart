import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/food_log_entry.dart';
import '../../../../shared/widgets/info_card.dart';

/// Interactive Daily Calorie Tracker, Protein/Carbs/Fat Tracker, and Food Log.
class DailyNutritionTrackerCard extends ConsumerWidget {
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;

  const DailyNutritionTrackerCard({
    super.key,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
  });

  Future<void> _showLogFoodDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1 serving');
    final calCtrl = TextEditingController();
    final proteinCtrl = TextEditingController(text: '0');
    final carbsCtrl = TextEditingController(text: '0');
    final fatCtrl = TextEditingController(text: '0');
    String mealLabel = 'Breakfast';

    final entry = await showDialog<FoodLogEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Food Entry', style: AppTextStyles.titleLarge),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: mealLabel,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Meal Slot',
                      isDense: true,
                    ),
                    items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => mealLabel = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Food / Meal Name',
                      hintText: 'e.g. Oatmeal & Whey',
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a food name' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Portion',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: calCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Calories (kcal)',
                            isDense: true,
                          ),
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null || n < 0) return 'Enter kcal';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: proteinCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TextFormField(
                          controller: carbsCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TextFormField(
                          controller: fatCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Fat (g)',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop(
                  FoodLogEntry(
                    id: 'FOOD-${DateTime.now().millisecondsSinceEpoch}',
                    foodName: nameCtrl.text.trim(),
                    quantity: qtyCtrl.text.trim().isEmpty
                        ? '1 serving'
                        : qtyCtrl.text.trim(),
                    mealLabel: mealLabel,
                    calories: int.tryParse(calCtrl.text.trim()) ?? 0,
                    protein: double.tryParse(proteinCtrl.text.trim()) ?? 0.0,
                    carbohydrates: double.tryParse(carbsCtrl.text.trim()) ?? 0.0,
                    fat: double.tryParse(fatCtrl.text.trim()) ?? 0.0,
                    consumedAt: DateTime.now(),
                  ),
                );
              },
              child: const Text('Save Food'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    qtyCtrl.dispose();
    calCtrl.dispose();
    proteinCtrl.dispose();
    carbsCtrl.dispose();
    fatCtrl.dispose();

    if (entry != null) {
      await ref.read(foodLogsProvider.notifier).addFoodEntry(entry);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppResponsive.isMobile(context);
    final logs = ref.watch(foodLogsProvider).value ?? const <FoodLogEntry>[];

    final consumedCalories = logs.fold<int>(0, (s, e) => s + e.calories);
    final consumedProtein = logs.fold<double>(0.0, (s, e) => s + e.protein);
    final consumedCarbs = logs.fold<double>(0.0, (s, e) => s + e.carbohydrates);
    final consumedFat = logs.fold<double>(0.0, (s, e) => s + e.fat);

    final remainingCalories = (targetCalories - consumedCalories).clamp(0, targetCalories);
    final calProgress =
        targetCalories > 0 ? (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;

    return InfoCard(
      title: 'Daily Calorie & Macro Tracker',
      subtitle: 'Track consumed calories, protein, carbs, fat & logged foods today',
      icon: Icons.track_changes_rounded,
      trailing: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkCharcoal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text(
          'Log Food',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showLogFoodDialog(context, ref),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calorie Intake Progress
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Daily Calorie Intake',
                        style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        '$consumedCalories / $targetCalories kcal',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.limeAccentDark,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: AppRadius.roundedFull,
                  child: LinearProgressIndicator(
                    value: calProgress,
                    minHeight: 7,
                    backgroundColor: AppColors.cardBackground,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.limeAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$remainingCalories kcal remaining today',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm + 2),

          // Protein, Carbohydrates & Fat Progress Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;
              final tiles = [
                _MacroProgressTile(
                  label: 'Protein',
                  consumed: consumedProtein,
                  target: targetProtein.toDouble(),
                  color: AppColors.limeAccentDark,
                ),
                _MacroProgressTile(
                  label: 'Carbs',
                  consumed: consumedCarbs,
                  target: targetCarbs.toDouble(),
                  color: AppColors.info,
                ),
                _MacroProgressTile(
                  label: 'Fat',
                  consumed: consumedFat,
                  target: targetFat.toDouble(),
                  color: AppColors.warning,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: tiles[1]),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: tiles[2]),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  tiles[2],
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.sm + 2),

          // Food Log List Header
          Text(
            'Today\'s Food Log (${logs.length})',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs + 2),

          if (logs.isEmpty)
            Text(
              'No foods logged today yet. Tap "Log Food" above or "Log Meal" on any scheduled meal below.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: logs.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBackground,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.foodName} (${item.mealLabel})',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.quantity} • ${item.calories} kcal • P ${item.protein.toStringAsFixed(0)}g / C ${item.carbohydrates.toStringAsFixed(0)}g / F ${item.fat.toStringAsFixed(0)}g • ${AppFormatters.formatTime(item.consumedAt)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 17),
                        color: AppColors.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        tooltip: 'Remove entry',
                        onPressed: () =>
                            ref.read(foodLogsProvider.notifier).deleteFoodEntry(item.id),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MacroProgressTile extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;

  const _MacroProgressTile({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}g',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: AppRadius.roundedFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
