import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/membership.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

/// Modal dialog / sheet for renewing or switching membership subscriptions.
class RenewMembershipModal extends ConsumerStatefulWidget {
  final String currentPlanId;
  final String memberId;

  const RenewMembershipModal({
    super.key,
    required this.currentPlanId,
    required this.memberId,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentPlanId,
    required String memberId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RenewMembershipModal(
        currentPlanId: currentPlanId,
        memberId: memberId,
      ),
    );
  }

  @override
  ConsumerState<RenewMembershipModal> createState() => _RenewMembershipModalState();
}

class _RenewMembershipModalState extends ConsumerState<RenewMembershipModal> {
  String? _selectedPlanId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.currentPlanId;
  }

  String _resolveSelectedPlanId(List<Membership> plans) {
    if (_selectedPlanId != null && plans.any((p) => p.id == _selectedPlanId)) {
      return _selectedPlanId!;
    }
    return plans.first.id;
  }

  Future<void> _handleConfirmRenewal(List<Membership> plans) async {
    final resolvedId = _resolveSelectedPlanId(plans);
    final plan = plans.firstWhere((p) => p.id == resolvedId, orElse: () => plans.first);

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(memberRepositoryProvider);
      await repo.renewMembership(memberId: widget.memberId, planId: plan.id);

      // Invalidate membership & billing providers to reflect pending renewal request
      ref.invalidate(membershipProvider);
      ref.invalidate(membershipHistoryProvider);
      ref.invalidate(currentMemberProvider);
      ref.invalidate(paymentHistoryProvider);
      ref.invalidate(pendingPaymentAmountProvider);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Renewal request submitted for ${plan.planName}! Pending payment/verification.',
          ),
          backgroundColor: AppColors.darkCharcoal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to renew membership: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availablePlansAsync = ref.watch(availablePlansProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
        maxWidth: 640,
      ),
      margin: EdgeInsets.only(
        top: 40,
        left: MediaQuery.of(context).size.width > 640 ? (MediaQuery.of(context).size.width - 640) / 2 : 0,
        right: MediaQuery.of(context).size.width > 640 ? (MediaQuery.of(context).size.width - 640) / 2 : 0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: AppRadius.roundedFull,
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Renew Membership', style: AppTextStyles.h2),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a renewal tier for Member ID: ${widget.memberId}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // Content body
          Expanded(
            child: availablePlansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading plans: $err')),
              data: (plans) {
                if (plans.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'No Plans Available',
                    message: 'There are currently no membership plans configured for renewal.',
                  );
                }

                final activeSelectionId = _resolveSelectedPlanId(plans);

                return ListView.separated(
                  padding: AppResponsive.cardPaddingLg(context),
                  itemCount: plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isSelected = plan.id == activeSelectionId;

                    return InkWell(
                      onTap: () => setState(() => _selectedPlanId = plan.id),
                      borderRadius: AppRadius.roundedLg,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.limeAccent.withValues(alpha: 0.1)
                              : AppColors.cardBackground,
                          borderRadius: AppRadius.roundedLg,
                          border: Border.all(
                            color: isSelected ? AppColors.limeAccentDark : AppColors.borderSubtle,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.darkCharcoal : AppColors.borderStrong,
                                      width: isSelected ? 6.0 : 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(plan.planName, style: AppTextStyles.titleLarge),
                                      Text(plan.durationMonths, style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                Text(
                                  AppFormatters.formatCurrency(plan.price),
                                  style: AppTextStyles.h2.copyWith(fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(color: AppColors.borderSubtle),
                            const SizedBox(height: AppSpacing.sm),

                            // Benefits list from plan
                            ...plan.benefits.map((benefit) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.limeAccentDark),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Modal Actions
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
            ),
            child: availablePlansAsync.maybeWhen(
              data: (plans) {
                if (plans.isEmpty) return const SizedBox.shrink();
                return Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: 'Confirm Renewal',
                        icon: Icons.check_circle_outline,
                        isLoading: _isSubmitting,
                        onPressed: () => _handleConfirmRenewal(plans),
                      ),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
