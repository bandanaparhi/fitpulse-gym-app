import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/fitness_measurement.dart';
import 'add_edit_measurement_modal.dart';

/// Dedicated Muscle Growth & Recomposition Tracking card built strictly from
/// recorded [FitnessMeasurement] entries (`muscleMassKg`, `chestCm`, `bodyFatPercentage`).
class MuscleGrowthCard extends StatelessWidget {
  final List<FitnessMeasurement> measurements;
  final bool isMetric;
  final ValueChanged<FitnessMeasurement> onSaveMeasurement;

  const MuscleGrowthCard({
    super.key,
    required this.measurements,
    required this.isMetric,
    required this.onSaveMeasurement,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<FitnessMeasurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    final muscleEntries = sorted.where((m) => m.muscleMassKg != null).toList();
    final chestEntries = sorted.where((m) => m.chestCm != null).toList();
    final bfEntries = sorted.where((m) => m.bodyFatPercentage != null).toList();

    final latestMuscle = muscleEntries.isNotEmpty ? muscleEntries.last : null;
    final firstMuscle = muscleEntries.isNotEmpty ? muscleEntries.first : null;

    final latestChest = chestEntries.isNotEmpty ? chestEntries.last : null;
    final firstChest = chestEntries.isNotEmpty ? chestEntries.first : null;

    final latestBf = bfEntries.isNotEmpty ? bfEntries.last : null;
    final firstBf = bfEntries.isNotEmpty ? bfEntries.first : null;

    final massUnit = isMetric ? 'kg' : 'lb';
    final lengthUnit = isMetric ? 'cm' : 'in';

    String muscleValue = '--';
    String muscleDelta = 'No muscle mass logged';
    if (latestMuscle != null) {
      final curr =
          isMetric ? latestMuscle.muscleMassKg! : latestMuscle.muscleMassLb!;
      muscleValue = '${curr.toStringAsFixed(1)} $massUnit';
      if (firstMuscle != null && muscleEntries.length > 1) {
        final base =
            isMetric ? firstMuscle.muscleMassKg! : firstMuscle.muscleMassLb!;
        final diff = curr - base;
        final sign = diff > 0 ? '+' : '';
        muscleDelta = '$sign${diff.toStringAsFixed(1)} $massUnit since initial';
      } else {
        muscleDelta = 'Baseline recorded';
      }
    }

    String chestValue = '--';
    String chestDelta = 'No chest measurement logged';
    if (latestChest != null) {
      final curr = isMetric ? latestChest.chestCm! : latestChest.chestInches!;
      chestValue = '${curr.toStringAsFixed(1)} $lengthUnit';
      if (firstChest != null && chestEntries.length > 1) {
        final base = isMetric ? firstChest.chestCm! : firstChest.chestInches!;
        final diff = curr - base;
        final sign = diff > 0 ? '+' : '';
        chestDelta = '$sign${diff.toStringAsFixed(1)} $lengthUnit growth';
      } else {
        chestDelta = 'Baseline recorded';
      }
    }

    String recompValue = '--';
    String recompSub = 'Requires 2+ scans';
    if (muscleEntries.length > 1) {
      final mCurr =
          isMetric ? latestMuscle!.muscleMassKg! : latestMuscle!.muscleMassLb!;
      final mBase =
          isMetric ? firstMuscle!.muscleMassKg! : firstMuscle!.muscleMassLb!;
      final mDiff = mCurr - mBase;
      final mSign = mDiff > 0 ? '+' : '';
      if (bfEntries.length > 1) {
        final bfDiff =
            latestBf!.bodyFatPercentage! - firstBf!.bodyFatPercentage!;
        final bfSign = bfDiff > 0 ? '+' : '';
        recompValue = '$mSign${mDiff.toStringAsFixed(1)} $massUnit Lean';
        recompSub = '$bfSign${bfDiff.toStringAsFixed(1)}% body fat change';
      } else {
        recompValue = '$mSign${mDiff.toStringAsFixed(1)} $massUnit Lean';
        recompSub = '${muscleEntries.length} scans recorded';
      }
    }

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.fitness_center_rounded,
                    color: AppColors.darkCharcoal,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Muscle Growth Tracking',
                      style: AppTextStyles.h3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                icon: const Icon(Icons.add_chart_rounded, size: 16),
                label: const Text(
                  'Log Muscle Scan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  AddEditMeasurementModal.show(
                    context,
                    isMetric: isMetric,
                    onSave: onSaveMeasurement,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Skeletal muscle mass, chest hypertrophy, and body recomposition trends.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                _MuscleMetricTile(
                  icon: Icons.accessibility_new_rounded,
                  accent: AppColors.limeAccentDark,
                  label: 'Skeletal Muscle Mass',
                  value: muscleValue,
                  subtitle: muscleDelta,
                ),
                _MuscleMetricTile(
                  icon: Icons.straighten_rounded,
                  accent: AppColors.info,
                  label: 'Chest Measurement',
                  value: chestValue,
                  subtitle: chestDelta,
                ),
                _MuscleMetricTile(
                  icon: Icons.trending_up_rounded,
                  accent: AppColors.success,
                  label: 'Recomposition Delta',
                  value: recompValue,
                  subtitle: recompSub,
                ),
              ];

              if (constraints.maxWidth >= 720) {
                return Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: tiles[1]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: tiles[2]),
                  ],
                );
              }

              return Column(
                children: [
                  tiles[0],
                  const SizedBox(height: AppSpacing.sm),
                  tiles[1],
                  const SizedBox(height: AppSpacing.sm),
                  tiles[2],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MuscleMetricTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String subtitle;

  const _MuscleMetricTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: AppSpacing.xs),
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
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.limeAccentDark,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
