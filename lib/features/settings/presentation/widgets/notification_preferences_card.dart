import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../data/models/notification_preferences.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Card for managing member push and in-app notification alert channels:
/// - Membership reminders
/// - Payment reminders
/// - Workout reminders
/// - Class reminders
/// - Gym announcements
class NotificationPreferencesCard extends ConsumerStatefulWidget {
  const NotificationPreferencesCard({super.key});

  @override
  ConsumerState<NotificationPreferencesCard> createState() =>
      _NotificationPreferencesCardState();
}

class _NotificationPreferencesCardState
    extends ConsumerState<NotificationPreferencesCard> {
  NotificationPreferences? _localPreferences;
  bool _isSaving = false;

  void _initFromPreferences(NotificationPreferences prefs) {
    _localPreferences ??= prefs;
  }

  Future<void> _handleSave() async {
    if (_localPreferences == null || _isSaving) return;

    setState(() => _isSaving = true);

    final success = await ref
        .read(notificationPreferencesProvider.notifier)
        .updatePreferences(_localPreferences!);

    if (mounted) {
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Notification preferences saved successfully!'
                : 'Failed to update preferences. Please try again.',
          ),
          backgroundColor:
              success ? AppColors.darkCharcoal : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardSubtleBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.limeAccent.withValues(alpha: 0.15)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value ? AppColors.limeAccentDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.limeAccentDark,
            activeTrackColor: AppColors.limeAccent.withValues(alpha: 0.4),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.borderSubtle,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: AppResponsive.cardPaddingLg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                  color: AppColors.limeAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Preferences',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose which gym notifications, billing alerts, and workout reminders you receive.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.lg),

          prefsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: LoadingIndicator(message: 'Loading preferences...'),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Unable to load notification preferences: $err',
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
            data: (savedPrefs) {
              _initFromPreferences(savedPrefs);
              final current = _localPreferences ?? savedPrefs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreferenceTile(
                    icon: Icons.card_membership_rounded,
                    title: 'Membership Reminders',
                    subtitle:
                        'Membership expiry notices, upcoming renewals, and tier status alerts.',
                    value: current.membershipReminders,
                    onChanged: (val) {
                      setState(() {
                        _localPreferences = current.copyWith(
                          membershipReminders: val,
                        );
                      });
                    },
                  ),
                  _buildPreferenceTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Payment Reminders',
                    subtitle:
                        'Invoice dues, pending payment notifications, and payment receipts.',
                    value: current.paymentReminders,
                    onChanged: (val) {
                      setState(() {
                        _localPreferences = current.copyWith(
                          paymentReminders: val,
                        );
                      });
                    },
                  ),
                  _buildPreferenceTile(
                    icon: Icons.fitness_center_rounded,
                    title: 'Workout Reminders',
                    subtitle:
                        'Assigned routine reminders, rest interval prompts, and streak notifications.',
                    value: current.workoutReminders,
                    onChanged: (val) {
                      setState(() {
                        _localPreferences = current.copyWith(
                          workoutReminders: val,
                        );
                      });
                    },
                  ),
                  _buildPreferenceTile(
                    icon: Icons.water_drop_outlined,
                    title: 'Water Intake Reminders',
                    subtitle:
                        'Daily hydration target alerts and fluid intake check-in nudges.',
                    value: current.waterIntakeReminders,
                    onChanged: (val) {
                      setState(() {
                        _localPreferences = current.copyWith(
                          waterIntakeReminders: val,
                        );
                      });
                    },
                  ),
                  _buildPreferenceTile(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Diet & Meal Reminders',
                    subtitle:
                        'Breakfast, lunch, and dinner schedule alerts plus macro logging reminders.',
                    value: current.dietReminders,
                    onChanged: (val) {
                      setState(() {
                        _localPreferences = current.copyWith(
                          dietReminders: val,
                        );
                      });
                    },
                  ),
                  _buildPreferenceTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'Class Reminders',
                    subtitle:
                        'Upcoming booked group classes, instructor changes, and seat confirmations.',
                    value: current.classReminders,
                    onChanged: (val) {
                      setState(() {
                        _localPreferences = current.copyWith(
                          classReminders: val,
                        );
                      });
                    },
                  ),
                  _buildPreferenceTile(
                    icon: Icons.campaign_rounded,
                    title: 'Gym Announcements',
                    subtitle:
                        'Official club notices, maintenance schedules, and holiday hours.',
                    value: current.gymAnnouncements,
                    onChanged: (val) {
                      setState(() {
                        _localPreferences = current.copyWith(
                          gymAnnouncements: val,
                        );
                      });
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Save Changes button
                  Align(
                    alignment: Alignment.centerRight,
                    child: PrimaryButton(
                      label: _isSaving ? 'Saving...' : 'Save Preferences',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? () {} : _handleSave,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
