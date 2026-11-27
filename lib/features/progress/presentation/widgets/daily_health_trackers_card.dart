import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../data/models/daily_health_log.dart';
import '../../../../data/models/notification_preferences.dart';
import '../../../../shared/widgets/info_card.dart';

/// Daily wellness trackers for Step Counts, Calories Burned, Water Intake, and Sleep.
class DailyHealthTrackersCard extends ConsumerWidget {
  const DailyHealthTrackersCard({super.key});

  Future<void> _promptIntValue({
    required BuildContext context,
    required String title,
    required String label,
    required int initialValue,
    required ValueChanged<int> onSave,
  }) async {
    final controller = TextEditingController(text: initialValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: AppTextStyles.titleLarge),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 0) {
                Navigator.of(ctx).pop(parsed);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) onSave(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = AppResponsive.isMobile(context);
    final healthAsync = ref.watch(dailyHealthLogProvider);
    final log = healthAsync.value ?? const DailyHealthLog(dateKey: '');
    final notifier = ref.read(dailyHealthLogProvider.notifier);
    final notifPrefs = ref.watch(notificationPreferencesProvider).value ??
        const NotificationPreferences();

    final stepsTile = _TrackerTile(
      icon: Icons.directions_walk_rounded,
      accent: AppColors.limeAccentDark,
      title: 'Step Counts',
      valueText: '${log.steps} / ${log.stepsGoal}',
      unitLabel: 'steps',
      progress: log.stepsProgress,
      isMobile: isMobile,
      actions: [
        _QuickChip(label: '+1,000', onTap: () => notifier.addSteps(1000)),
        _QuickChip(label: '+2,500', onTap: () => notifier.addSteps(2500)),
        _QuickChip(
          label: 'Set',
          onTap: () => _promptIntValue(
            context: context,
            title: 'Update Today\'s Steps',
            label: 'Total steps',
            initialValue: log.steps,
            onSave: notifier.setSteps,
          ),
        ),
      ],
    );

    final caloriesTile = _TrackerTile(
      icon: Icons.local_fire_department_rounded,
      accent: AppColors.warning,
      title: 'Calories Burned',
      valueText: '${log.caloriesBurned} / ${log.caloriesGoal}',
      unitLabel: 'kcal',
      progress: log.caloriesProgress,
      isMobile: isMobile,
      actions: [
        _QuickChip(label: '+150', onTap: () => notifier.addCaloriesBurned(150)),
        _QuickChip(label: '+300', onTap: () => notifier.addCaloriesBurned(300)),
        _QuickChip(
          label: 'Set',
          onTap: () => _promptIntValue(
            context: context,
            title: 'Update Calories Burned',
            label: 'Calories burned (kcal)',
            initialValue: log.caloriesBurned,
            onSave: notifier.setCaloriesBurned,
          ),
        ),
      ],
    );

    final waterTile = _TrackerTile(
      icon: Icons.water_drop_rounded,
      accent: AppColors.info,
      title: 'Water Intake Tracker',
      valueText:
          '${(log.waterMl / 1000).toStringAsFixed(2)} / ${(log.waterGoalMl / 1000).toStringAsFixed(1)} L',
      unitLabel: '${log.waterMl} ml',
      progress: log.waterProgress,
      isMobile: isMobile,
      actions: [
        _QuickChip(label: '+250 ml', onTap: () => notifier.addWaterMl(250)),
        _QuickChip(label: '+500 ml', onTap: () => notifier.addWaterMl(500)),
        _QuickChip(label: '-250 ml', onTap: () => notifier.addWaterMl(-250)),
        _QuickChip(
          label: notifPrefs.waterIntakeReminders
              ? 'Reminder: ON'
              : 'Reminder: OFF',
          onTap: () {
            ref
                .read(notificationPreferencesProvider.notifier)
                .updatePreferences(
                  notifPrefs.copyWith(
                    waterIntakeReminders: !notifPrefs.waterIntakeReminders,
                  ),
                );
          },
        ),
      ],
    );

    final sleepTile = _TrackerTile(
      icon: Icons.bedtime_rounded,
      accent: AppColors.darkCharcoal,
      title: 'Sleep Tracking',
      valueText:
          '${log.sleepHours.toStringAsFixed(1)} / ${log.sleepGoalHours.toStringAsFixed(0)} hrs',
      unitLabel: 'sleep',
      progress: log.sleepProgress,
      isMobile: isMobile,
      actions: [
        _QuickChip(
          label: '-0.5h',
          onTap: () => notifier.setSleepHours(log.sleepHours - 0.5),
        ),
        _QuickChip(
          label: '+0.5h',
          onTap: () => notifier.setSleepHours(log.sleepHours + 0.5),
        ),
        _QuickChip(
          label: '+1h',
          onTap: () => notifier.setSleepHours(log.sleepHours + 1.0),
        ),
      ],
    );

    return InfoCard(
      title: 'Daily Activity, Water & Sleep',
      subtitle: 'Log daily steps, calories burned, hydration, and sleep hours',
      icon: Icons.favorite_outline_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 700;
          final gap = isMobile ? AppSpacing.sm : AppSpacing.md;

          if (!isDesktop) {
            return Column(
              children: [
                stepsTile,
                SizedBox(height: gap),
                caloriesTile,
                SizedBox(height: gap),
                waterTile,
                SizedBox(height: gap),
                sleepTile,
              ],
            );
          }

          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: stepsTile),
                    SizedBox(width: gap),
                    Expanded(child: caloriesTile),
                  ],
                ),
              ),
              SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: waterTile),
                    SizedBox(width: gap),
                    Expanded(child: sleepTile),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrackerTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String valueText;
  final String unitLabel;
  final double progress;
  final bool isMobile;
  final List<Widget> actions;

  const _TrackerTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.valueText,
    required this.unitLabel,
    required this.progress,
    required this.isMobile,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: isMobile ? 13 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                unitLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valueText,
            style: AppTextStyles.h3.copyWith(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.roundedFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: actions,
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: AppRadius.roundedSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.roundedSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: AppRadius.roundedSm,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
