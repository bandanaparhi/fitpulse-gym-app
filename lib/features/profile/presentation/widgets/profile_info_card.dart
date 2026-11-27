import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/member.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Card presenting the member's profile photo, identity credentials, contact info,
/// date of birth, emergency contact, and Edit Profile trigger.
class ProfileInfoCard extends StatelessWidget {
  final Member member;
  final VoidCallback onEditProfile;

  const ProfileInfoCard({
    super.key,
    required this.member,
    required this.onEditProfile,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
    bool allowCopy = false,
  }) {
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
          Icon(icon, size: 20, color: AppColors.darkCharcoal),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (allowCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: 'Copy $label',
              onPressed: () => _copyToClipboard(context, value, label),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = member.name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

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
          // Header: Avatar, Name, Member ID, and Edit Profile Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final avatarWidget = Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.limeAccentDark,
                    width: 2,
                  ),
                ),
                child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                        child: Image.network(
                          member.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              initials,
                              style: AppTextStyles.h2.copyWith(
                                color: AppColors.limeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.limeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              );

              final identityDetails = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: 4,
                    children: [
                      Text(
                        member.name,
                        style: AppTextStyles.h2,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.limeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.limeAccentDark
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${member.membershipPlan.toUpperCase()} • ${member.membershipStatus.toUpperCase()}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.limeAccentDark,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: 2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Member ID: ${member.id}',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Joined ${AppFormatters.formatDate(member.joinedDate)}',
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
                  ),
                ],
              );

              final editButton = PrimaryButton(
                label: 'Edit Profile',
                icon: Icons.edit_outlined,
                onPressed: onEditProfile,
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        avatarWidget,
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: identityDetails),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: editButton,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  avatarWidget,
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: identityDetails),
                  const SizedBox(width: AppSpacing.md),
                  editButton,
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Information Details Grid
          Text(
            'Personal & Emergency Information',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;

              final emailTile = _buildInfoTile(
                context: context,
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: member.email,
                allowCopy: true,
              );

              final phoneTile = _buildInfoTile(
                context: context,
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: member.phone,
                allowCopy: true,
              );

              final dobTile = _buildInfoTile(
                context: context,
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: member.dateOfBirth != null
                    ? AppFormatters.formatDate(member.dateOfBirth!)
                    : 'Not provided',
              );

              final emergencyTile = _buildInfoTile(
                context: context,
                icon: Icons.contact_emergency_outlined,
                label: 'Emergency Contact',
                value: member.emergencyContact ?? 'Not provided',
              );

              if (isNarrow) {
                return Column(
                  children: [
                    emailTile,
                    const SizedBox(height: AppSpacing.sm),
                    phoneTile,
                    const SizedBox(height: AppSpacing.sm),
                    dobTile,
                    const SizedBox(height: AppSpacing.sm),
                    emergencyTile,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: emailTile),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: phoneTile),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: dobTile),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: emergencyTile),
                    ],
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
