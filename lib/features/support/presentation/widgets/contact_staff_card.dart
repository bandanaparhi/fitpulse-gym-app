import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Card displaying configured gym contact details and facility staff information.
/// If a contact channel (such as phone support) is unconfigured, displays a clear message
/// rather than inventing fake contact information.
class ContactStaffCard extends ConsumerWidget {
  const ContactStaffCard({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildChannelTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Icon(icon, size: 20, color: AppColors.darkCharcoal),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            SecondaryButton(
              label: actionLabel,
              height: 36,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(gymContactInfoProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.support_agent_outlined,
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
                      'Contact Gym Staff & Front Desk',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reach out to on-site reception, administration, or your personal coach.',
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

          contactAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: LoadingIndicator(message: 'Loading contact details...'),
              ),
            ),
            error: (err, _) => ErrorState(
              title: 'Unable to load contact information',
              message: err.toString(),
              onRetry: () => ref.invalidate(gymContactInfoProvider),
            ),
            data: (info) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Official Support Email
                  if (info.hasEmail)
                    _buildChannelTile(
                      context: context,
                      icon: Icons.email_outlined,
                      title: 'Customer Support Email',
                      value: info.email!,
                      actionLabel: 'Copy',
                      onAction: () =>
                          _copyToClipboard(context, info.email!, 'Support email'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.cardSubtleBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        'Support email is currently not configured for this facility.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                  // Phone Support Status
                  if (info.hasPhone)
                    _buildChannelTile(
                      context: context,
                      icon: Icons.phone_outlined,
                      title: 'Front Desk Hotline',
                      value: info.phone!,
                      actionLabel: 'Copy',
                      onAction: () =>
                          _copyToClipboard(context, info.phone!, 'Phone number'),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.phone_disabled_outlined,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone Support Not Configured',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Direct phone hotline support is not configured for this facility. Please email support@fitpulse.com, speak to staff in-person at the front desk, or message your trainer below.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Physical Facility & Operating Hours
                  if (info.hasAddress)
                    _buildChannelTile(
                      context: context,
                      icon: Icons.location_on_outlined,
                      title: 'Gym Location',
                      value: info.address!,
                    ),

                  if (info.hasOperatingHours)
                    _buildChannelTile(
                      context: context,
                      icon: Icons.access_time_rounded,
                      title: 'Staffed Facility Hours',
                      value: info.operatingHours!,
                    ),

                  // Assigned Trainer Quick Access
                  if (info.assignedTrainerName != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: AppColors.limeAccentDark.withValues(alpha: 0.3),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final isNarrow = box.maxWidth < 420;
                          final trainerInfo = Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCharcoal,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(
                                  Icons.fitness_center_rounded,
                                  size: 18,
                                  color: AppColors.limeAccent,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assigned Personal Coach',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      info.assignedTrainerName!,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );

                          final actionBtn = SecondaryButton(
                            label: 'Message Coach',
                            icon: Icons.chat_bubble_outline_rounded,
                            height: 36,
                            onPressed: () => context.go('/trainer'),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                trainerInfo,
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: actionBtn,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: trainerInfo),
                              const SizedBox(width: AppSpacing.md),
                              actionBtn,
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
