import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/fitness_measurement.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import 'add_edit_measurement_modal.dart';

/// Body Measurements table and history card with add/edit/delete actions and unit toggling.
class BodyMeasurementsCard extends StatelessWidget {
  final List<FitnessMeasurement> measurements;
  final bool isMetric;
  final VoidCallback onToggleUnit;
  final ValueChanged<FitnessMeasurement> onSaveMeasurement;
  final ValueChanged<String> onDeleteMeasurement;

  const BodyMeasurementsCard({
    super.key,
    required this.measurements,
    required this.isMetric,
    required this.onToggleUnit,
    required this.onSaveMeasurement,
    required this.onDeleteMeasurement,
  });

  @override
  Widget build(BuildContext context) {
    // Show newest first
    final sorted = List<FitnessMeasurement>.from(measurements)
      ..sort((a, b) => b.date.compareTo(a.date));

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final titleInfo = Row(
                children: [
                  const Icon(
                    Icons.straighten_rounded,
                    color: AppColors.darkCharcoal,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Body Measurements Log',
                    style: AppTextStyles.h3,
                  ),
                ],
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Unit Toggle Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      side: const BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      isMetric ? 'Metric (kg, cm)' : 'Imperial (lb, in)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: onToggleUnit,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Add Measurement CTA
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkCharcoal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Log Entry',
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
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleInfo,
                    const SizedBox(height: AppSpacing.md),
                    actionButtons,
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    titleInfo,
                    actionButtons,
                  ],
                );
              }
            },
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Measurements List
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No body measurements logged yet. Click "Log Entry" to record your progress.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final item = sorted[index];
                return _buildMeasurementTile(context, item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTile(BuildContext context, FitnessMeasurement item) {
    final weightStr = isMetric
        ? '${item.weightKg.toStringAsFixed(1)} kg'
        : '${item.weightLb.toStringAsFixed(1)} lb';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    AppFormatters.formatDate(item.date),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Action
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Edit Measurement',
                    onPressed: () {
                      AddEditMeasurementModal.show(
                        context,
                        measurement: item,
                        isMetric: isMetric,
                        onSave: onSaveMeasurement,
                      );
                    },
                  ),
                  // Delete Action with Confirmation
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete Measurement',
                    onPressed: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Delete Measurement?',
                        message:
                            'Are you sure you want to delete the measurement entry from ${AppFormatters.formatShortDate(item.date)}? This action cannot be undone.',
                        confirmLabel: 'Delete Entry',
                        isDestructive: true,
                      );
                      if (confirmed == true) {
                        onDeleteMeasurement(item.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Metrics Wrap Row
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _buildValueChip(
                label: 'Weight',
                value: weightStr,
                isHighlight: true,
              ),
              if (item.bodyFatPercentage != null)
                _buildValueChip(
                  label: 'Body Fat',
                  value: '${item.bodyFatPercentage!.toStringAsFixed(1)}%',
                ),
              if (item.muscleMassKg != null)
                _buildValueChip(
                  label: 'Muscle Mass',
                  value: isMetric
                      ? '${item.muscleMassKg!.toStringAsFixed(1)} kg'
                      : '${item.muscleMassLb!.toStringAsFixed(1)} lb',
                ),
              if (item.waistCm != null)
                _buildValueChip(
                  label: 'Waist',
                  value: isMetric
                      ? '${item.waistCm!.toStringAsFixed(1)} cm'
                      : '${item.waistInches!.toStringAsFixed(1)} in',
                ),
              if (item.chestCm != null)
                _buildValueChip(
                  label: 'Chest',
                  value: isMetric
                      ? '${item.chestCm!.toStringAsFixed(1)} cm'
                      : '${item.chestInches!.toStringAsFixed(1)} in',
                ),
              if (item.bmi != null)
                _buildValueChip(
                  label: 'BMI',
                  value: item.bmi!.toStringAsFixed(1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.limeAccent.withValues(alpha: 0.15)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isHighlight
              ? AppColors.limeAccentDark.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.darkCharcoal : AppColors.textPrimary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
