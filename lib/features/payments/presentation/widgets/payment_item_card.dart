import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/member.dart';
import '../../../../data/models/payment.dart';
import 'receipt_view_dialog.dart';

/// Card item representing a payment record in the payment history list.
class PaymentItemCard extends StatelessWidget {
  final Payment payment;
  final Member? member;

  const PaymentItemCard({
    super.key,
    required this.payment,
    this.member,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.darkCharcoal;
    }
  }

  IconData _getMethodIcon(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('card')) return Icons.credit_card_rounded;
    if (lower.contains('upi')) return Icons.qr_code_rounded;
    if (lower.contains('bank')) return Icons.account_balance_rounded;
    return Icons.payments_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(payment.status);
    final methodIcon = _getMethodIcon(payment.paymentMethod);

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
          // Top Row: Date, Invoice number & Status badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  Text(
                    AppFormatters.formatDate(payment.date),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '•  ${payment.invoiceNumber}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Main Info: Description, Amount, Payment Method
          LayoutBuilder(
            builder: (context, box) {
              final isNarrow = box.maxWidth < 420;
              final detailsColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.description,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.md,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(methodIcon, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              payment.paymentMethod,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'ID: ${payment.id}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final amountWidget = Text(
                AppFormatters.formatCurrency(payment.amount),
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    detailsColumn,
                    const SizedBox(height: AppSpacing.sm),
                    amountWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: detailsColumn),
                  const SizedBox(width: AppSpacing.md),
                  amountWidget,
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Actions Row: View Receipt & Transaction Details
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.receipt_outlined, size: 16),
                label: const Text('View Receipt'),
                onPressed: () => ReceiptViewDialog.show(
                  context,
                  payment: payment,
                  member: member,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Details'),
                onPressed: () => context.go('/payments/${payment.id}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
