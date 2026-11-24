import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/membership.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/membership_progress_timeline.dart';
import 'widgets/membership_status_badge.dart';
import 'widgets/renew_membership_modal.dart';

/// My Membership screen at `/membership`.
///
/// Displays:
/// - Plan name, Member ID, Status, Start/Expiry dates, Duration
/// - Included benefits
/// - Visual progress timeline
/// - Previous membership history
/// - Renew Membership modal trigger
/// - Empty, loading, and error states
class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);
    final membershipAsync = ref.watch(membershipProvider);
    final historyAsync = ref.watch(membershipHistoryProvider);

    return memberAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: LoadingIndicator(message: 'Loading membership details...'),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: ErrorState(
          title: 'Unable to Load Membership',
          message: err.toString(),
          onRetry: () {
            ref.invalidate(currentMemberProvider);
            ref.invalidate(membershipProvider);
          },
        ),
      ),
      data: (member) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              PageHeader(
                title: 'My Membership',
                subtitle: 'Manage subscription tier, benefits, and renewals',
                trailing: membershipAsync.maybeWhen(
                  data: (plan) => plan != null
                      ? PrimaryButton(
                          label: 'Renew Membership',
                          icon: Icons.autorenew_rounded,
                          onPressed: () => RenewMembershipModal.show(
                            context,
                            currentPlanId: plan.id,
                            memberId: member.id,
                          ),
                        )
                      : null,
                  orElse: () => null,
                ),
              ),

              // Membership Content
              membershipAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => ErrorState(
                  title: 'Error loading plan',
                  message: err.toString(),
                  onRetry: () => ref.invalidate(membershipProvider),
                ),
                data: (membership) {
                  // Empty state when no active subscription exists
                  if (membership == null) {
                    return InfoCard(
                      child: EmptyState(
                        icon: Icons.card_membership_outlined,
                        title: 'No Active Membership',
                        message:
                            'You do not currently have an active gym membership subscription. Browse available plans to get started.',
                        actionLabel: 'Choose a Plan',
                        onAction: () => RenewMembershipModal.show(
                          context,
                          currentPlanId: 'MEM-PREM-2026',
                          memberId: member.id,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Primary Active Plan Card
                      _buildActivePlanCard(context, member, membership),
                      const SizedBox(height: AppSpacing.lg),

                      // 2. Membership Timeline Card
                      MembershipProgressTimeline(
                        startDate: membership.startDate,
                        expiryDate: membership.expiryDate,
                        durationMonths: membership.durationMonths,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 3. Included Benefits Section
                      _buildBenefitsCard(context, membership),
                      const SizedBox(height: AppSpacing.lg),

                      // 4. Previous Membership History
                      historyAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (history) => _buildHistoryCard(context, history),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivePlanCard(BuildContext context, dynamic member, Membership plan) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier Header & Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: AppRadius.roundedMd,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.limeAccent, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.planName,
                            style: AppTextStyles.h2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        MembershipStatusBadge(status: plan.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member ID: ${member.id} • Assigned to ${member.name}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Plan Details Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 720;
              final cols = isDesktop ? 4 : 2;

              return GridView.count(
                crossAxisCount: cols,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isDesktop ? 2.6 : 2.2,
                children: [
                  _buildDetailTile(
                    label: 'Membership Price',
                    value: AppFormatters.formatCurrency(plan.price),
                    icon: Icons.payments_outlined,
                  ),
                  _buildDetailTile(
                    label: 'Plan Duration',
                    value: plan.durationMonths,
                    icon: Icons.date_range_outlined,
                  ),
                  _buildDetailTile(
                    label: 'Start Date',
                    value: AppFormatters.formatDate(plan.startDate),
                    icon: Icons.calendar_today_outlined,
                  ),
                  _buildDetailTile(
                    label: 'Expiry Date',
                    value: AppFormatters.formatDate(plan.expiryDate),
                    icon: Icons.event_available_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action row for mobile/compact screens
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Renew / Upgrade Membership',
                  icon: Icons.autorenew_rounded,
                  onPressed: () => RenewMembershipModal.show(
                    context,
                    currentPlanId: plan.id,
                    memberId: member.id,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(BuildContext context, Membership plan) {
    return InfoCard(
      title: 'Included Membership Benefits',
      subtitle: 'Exclusive perks and amenities included with your ${plan.planName}',
      icon: Icons.verified_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMultiCol = constraints.maxWidth >= 600;
          final cols = isMultiCol ? 2 : 1;

          return GridView.builder(
            itemCount: plan.benefits.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: isMultiCol ? 6.5 : 8.0,
            ),
            itemBuilder: (context, index) {
              final benefit = plan.benefits[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: AppColors.limeAccentDark),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      benefit,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, List<Membership> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    return InfoCard(
      title: 'Previous Membership History',
      subtitle: 'Archive of past subscriptions and renewals',
      icon: Icons.history_rounded,
      child: Column(
        children: history.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: const Icon(Icons.card_membership_rounded, size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.planName, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormatters.formatDate(item.startDate)} – ${AppFormatters.formatDate(item.expiryDate)} (${item.durationMonths})',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MembershipStatusBadge(status: item.status),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.formatCurrency(item.price),
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
