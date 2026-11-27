import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/profile_info_card.dart';

/// Screen displaying the member's profile, contact details, emergency contacts,
/// and edit flow at `/profile`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.cardSubtleBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.darkCharcoal),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        value,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: memberAsync.when(
        loading: () => const Center(
          child: LoadingIndicator(message: 'Loading member profile...'),
        ),
        error: (err, stack) => Center(
          child: ErrorState(
            title: 'Failed to load profile',
            message: err.toString(),
            onRetry: () => ref.invalidate(currentMemberProvider),
          ),
        ),
        data: (member) {
          final gapLg = AppResponsive.sectionGapLg(context);
          return SingleChildScrollView(
            padding: AppResponsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                const PageHeader(
                  title: 'My Profile',
                  subtitle:
                      'Manage your membership identity, contact information, and emergency details.',
                ),

                // Main Profile Info Card (Photo, Name, ID, Email, Phone, DOB, Emergency Contact, Edit Profile)
                ProfileInfoCard(
                  member: member,
                  onEditProfile: () => EditProfileDialog.show(
                    context,
                    member: member,
                    onSave: ({
                      required name,
                      required phone,
                      photoUrl,
                      emergencyContact,
                    }) =>
                        ref.read(currentMemberProvider.notifier).updateProfile(
                              name: name,
                              phone: phone,
                              photoUrl: photoUrl,
                              emergencyContact: emergencyContact,
                            ),
                  ),
                ),

                SizedBox(height: gapLg),

                // Protected Membership & Compliance Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  padding: AppResponsive.cardPaddingLg(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: AppColors.darkCharcoal,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Membership Status & Protected Records',
                              style: AppTextStyles.h3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Member ID, active subscription plan, and payment histories are system-governed compliance records and cannot be altered directly.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 650;
                          final tiles = [
                            _buildSummaryTile(
                              icon: Icons.card_membership_rounded,
                              label: 'Active Plan',
                              value:
                                  '${member.membershipPlan} (Expires ${AppFormatters.formatShortDate(member.membershipExpiry)})',
                              onTap: () => context.go('/membership'),
                            ),
                            _buildSummaryTile(
                              icon: Icons.receipt_long_rounded,
                              label: 'Payment Ledger',
                              value:
                                  '₹${member.pendingPaymentAmount.toStringAsFixed(0)} Pending • View Invoices',
                              onTap: () => context.go('/payments'),
                            ),
                            _buildSummaryTile(
                              icon: Icons.calendar_month_rounded,
                              label: 'Attendance Consistency',
                              value:
                                  '${member.attendanceCountThisMonth} Visits This Month',
                              onTap: () => context.go('/attendance'),
                            ),
                          ];

                          if (isNarrow) {
                            return Column(
                              children: [
                                for (final tile in tiles) ...[
                                  tile,
                                  const SizedBox(height: AppSpacing.sm),
                                ],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              for (int i = 0; i < tiles.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(width: AppSpacing.md),
                                Expanded(child: tiles[i]),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
