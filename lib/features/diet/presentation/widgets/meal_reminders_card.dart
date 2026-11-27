import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../data/models/food_log_entry.dart';
import '../../../../shared/widgets/info_card.dart';

/// Meal reminder preferences card for Breakfast, Lunch, and Dinner schedules.
class MealRemindersCard extends ConsumerWidget {
  const MealRemindersCard({super.key});

  Future<void> _pickMealTime({
    required BuildContext context,
    required WidgetRef ref,
    required MealReminderSettings settings,
    required String mealName,
    required String currentTime,
    required MealReminderSettings Function(String formatted) onUpdated,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && context.mounted) {
      final formatted = picked.format(context);
      await ref
          .read(mealReminderSettingsProvider.notifier)
          .updateSettings(onUpdated(formatted));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$mealName reminder set for $formatted'),
            backgroundColor: AppColors.darkCharcoal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(mealReminderSettingsProvider).value ??
        const MealReminderSettings();
    final notifier = ref.read(mealReminderSettingsProvider.notifier);

    return InfoCard(
      title: 'Meal Reminders',
      subtitle: 'Daily alerts for Breakfast, Lunch & Dinner timings',
      icon: Icons.notifications_active_outlined,
      trailing: Switch(
        value: settings.enabled,
        activeThumbColor: AppColors.limeAccent,
        activeTrackColor: AppColors.darkCharcoal,
        onChanged: (val) => notifier.updateSettings(settings.copyWith(enabled: val)),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          _ReminderChip(
            label: 'Breakfast',
            time: settings.breakfastTime,
            enabled: settings.enabled,
            onTap: () => _pickMealTime(
              context: context,
              ref: ref,
              settings: settings,
              mealName: 'Breakfast',
              currentTime: settings.breakfastTime,
              onUpdated: (t) => settings.copyWith(breakfastTime: t),
            ),
          ),
          _ReminderChip(
            label: 'Lunch',
            time: settings.lunchTime,
            enabled: settings.enabled,
            onTap: () => _pickMealTime(
              context: context,
              ref: ref,
              settings: settings,
              mealName: 'Lunch',
              currentTime: settings.lunchTime,
              onUpdated: (t) => settings.copyWith(lunchTime: t),
            ),
          ),
          _ReminderChip(
            label: 'Dinner',
            time: settings.dinnerTime,
            enabled: settings.enabled,
            onTap: () => _pickMealTime(
              context: context,
              ref: ref,
              settings: settings,
              mealName: 'Dinner',
              currentTime: settings.dinnerTime,
              onUpdated: (t) => settings.copyWith(dinnerTime: t),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final String label;
  final String time;
  final bool enabled;
  final VoidCallback onTap;

  const _ReminderChip({
    required this.label,
    required this.time,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        Icons.alarm_rounded,
        size: 15,
        color: enabled ? AppColors.limeAccentDark : AppColors.textMuted,
      ),
      label: Text(
        '$label: $time',
        style: AppTextStyles.caption.copyWith(
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onTap,
    );
  }
}
