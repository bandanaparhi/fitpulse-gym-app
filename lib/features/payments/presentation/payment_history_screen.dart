import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/payment_item_card.dart';
import 'widgets/pending_payment_card.dart';

/// Screen displaying the member's payment history, invoices, and receipts at `/payments`.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentHistoryProvider);
    final memberAsync = ref.watch(currentMemberProvider);
    final pendingAmountAsync = ref.watch(pendingPaymentAmountProvider);
    final isOnlinePaymentConfigured =
        ref.watch(isPaymentGatewayConfiguredProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: paymentsAsync.when(
        loading: () => const Center(
          child: LoadingIndicator(message: 'Loading your payment history...'),
        ),
        error: (err, stack) => Center(
          child: ErrorState(
            title: 'Failed to load payments',
            message: err.toString(),
            onRetry: () => ref.invalidate(paymentHistoryProvider),
          ),
        ),
        data: (payments) {
          final member = memberAsync.value;
          final pendingAmount = pendingAmountAsync.value ?? 0.0;
          final totalInvested = payments
              .where((p) => p.isPaid)
              .fold<double>(0.0, (sum, p) => sum + p.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                const PageHeader(
                  title: 'Payments & Billing History',
                  subtitle:
                      'View official invoices, payment receipts, and transaction records for your gym membership and services.',
                ),

                const SizedBox(height: AppSpacing.lg),

                // Pending Payment Banner / Online Availability Check
                PendingPaymentCard(
                  pendingAmount: pendingAmount,
                  isOnlinePaymentConfigured: isOnlinePaymentConfigured,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Summary KPIs
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    if (isNarrow) {
                      return Column(
                        children: [
                          _buildSummaryCard(
                            label: 'Total Paid to Date',
                            value: AppFormatters.formatCurrency(totalInvested),
                            icon: Icons.payments_rounded,
                            color: AppColors.limeAccentDark,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildSummaryCard(
                            label: 'Invoices Paid',
                            value: '${payments.where((p) => p.isPaid).length}',
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.info,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildSummaryCard(
                            label: 'Current Outstanding Dues',
                            value: AppFormatters.formatCurrency(pendingAmount),
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.darkCharcoal,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Total Paid to Date',
                            value: AppFormatters.formatCurrency(totalInvested),
                            icon: Icons.payments_rounded,
                            color: AppColors.limeAccentDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Invoices Paid',
                            value: '${payments.where((p) => p.isPaid).length}',
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildSummaryCard(
                            label: 'Current Outstanding Dues',
                            value: AppFormatters.formatCurrency(pendingAmount),
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.darkCharcoal,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Transactions List Section Header
                Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: AppColors.darkCharcoal,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Transaction History (${payments.length})',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Transactions List
                if (payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Payment Records Found',
                      message:
                          'Your transaction records and payment receipts will appear here once invoices are generated.',
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return PaymentItemCard(
                        payment: payment,
                        member: member,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
