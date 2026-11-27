import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_downloader.dart';
import '../../../data/models/member.dart';
import '../../../data/models/payment.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'widgets/receipt_view_dialog.dart';

/// Screen displaying in-depth details of a specific payment transaction at `/payments/:paymentId`.
class PaymentDetailsScreen extends ConsumerWidget {
  final String paymentId;

  const PaymentDetailsScreen({
    super.key,
    required this.paymentId,
  });

  Future<void> _handleDownloadReceipt(
    BuildContext context,
    Payment payment,
    Member? member,
  ) async {
    await ReceiptDownloader.downloadReceiptPdf(
      payment: payment,
      member: member,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Receipt "${payment.invoiceNumber}.pdf" downloaded successfully.',
        ),
        backgroundColor: AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
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
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: valueColor ?? AppColors.textPrimary,
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
    final paymentAsync = ref.watch(singlePaymentProvider(paymentId));
    final memberAsync = ref.watch(currentMemberProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: paymentAsync.when(
        loading: () => const Center(
          child: LoadingIndicator(message: 'Loading transaction record...'),
        ),
        error: (err, stack) => Center(
          child: ErrorState(
            title: 'Failed to load transaction',
            message: err.toString(),
            onRetry: () => ref.invalidate(singlePaymentProvider(paymentId)),
          ),
        ),
        data: (payment) {
          if (payment == null) {
            return Center(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Transaction Not Found',
                message:
                    'No payment record matching transaction reference "$paymentId" was found.',
                actionLabel: 'Return to Payment History',
                onAction: () => context.go('/payments'),
              ),
            );
          }

          final member = memberAsync.value;

          return SingleChildScrollView(
            padding: AppResponsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation & Page Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go('/payments'),
                      tooltip: 'Back to Payment History',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: PageHeader(
                        title: 'Payment Details',
                        subtitle:
                            'Transaction reference ID: ${payment.id} • Invoice ${payment.invoiceNumber}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Responsive Layout: Details Card & Receipt Actions
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 850;

                    final mainDetailsCard = Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status & Amount Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Paid Amount',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppFormatters.formatCurrency(payment.amount),
                                    style: AppTextStyles.h1.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: payment.isPaid
                                      ? AppColors.success
                                          .withValues(alpha: 0.15)
                                      : AppColors.warning
                                          .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(
                                    color: payment.isPaid
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      payment.isPaid
                                          ? Icons.check_circle_rounded
                                          : Icons.access_time_rounded,
                                      size: 16,
                                      color: payment.isPaid
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      payment.status.toUpperCase(),
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: payment.isPaid
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.lg),
                          const Divider(
                            color: AppColors.borderSubtle,
                            height: 1,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Transaction Key Fields
                          _buildDetailRow(
                            icon: Icons.tag_rounded,
                            label: 'Transaction ID',
                            value: payment.id,
                            isMonospace: true,
                          ),
                          _buildDetailRow(
                            icon: Icons.receipt_rounded,
                            label: 'Official Invoice Number',
                            value: payment.invoiceNumber,
                            isMonospace: true,
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Payment Date & Time',
                            value:
                                '${AppFormatters.formatDate(payment.date)} at ${AppFormatters.formatTime(payment.date)}',
                          ),
                          _buildDetailRow(
                            icon: Icons.fitness_center_rounded,
                            label: 'Membership / Service',
                            value: payment.effectiveServiceName,
                          ),
                          _buildDetailRow(
                            icon: Icons.description_outlined,
                            label: 'Description',
                            value: payment.description,
                          ),
                          _buildDetailRow(
                            icon: Icons.payment_rounded,
                            label: 'Payment Method',
                            value: payment.paymentMethod,
                          ),
                          _buildDetailRow(
                            icon: Icons.info_outline_rounded,
                            label: 'Payment Status',
                            value: payment.status,
                            valueColor: payment.isPaid
                                ? AppColors.success
                                : AppColors.warning,
                          ),

                          const SizedBox(height: AppSpacing.md),
                          const Divider(
                            color: AppColors.borderSubtle,
                            height: 1,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Cost Breakdown
                          Text(
                            'Tax & Fee Breakdown',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Service Subtotal:',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                AppFormatters.formatCurrency(
                                  payment.effectiveSubtotal,
                                ),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Goods & Services Tax (GST 18%):',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                AppFormatters.formatCurrency(
                                  payment.effectiveTaxAmount,
                                ),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Divider(
                            color: AppColors.borderSubtle,
                            height: 1,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Paid:',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AppFormatters.formatCurrency(payment.amount),
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.limeAccentDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    final sidebarActionCard = Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCharcoal,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: AppColors.limeAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Invoice & Receipt',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'An official computerized receipt is available for this transaction for tax deduction or employer wellness reimbursement.',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // View Official Receipt Button
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: 'View Official Receipt',
                              icon: Icons.remove_red_eye_outlined,
                              onPressed: () => ReceiptViewDialog.show(
                                context,
                                payment: payment,
                                member: member,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Download PDF Button
                          SizedBox(
                            width: double.infinity,
                            child: SecondaryButton(
                              label: 'Download Receipt (PDF)',
                              icon: Icons.download_rounded,
                              onPressed: () => _handleDownloadReceipt(
                                context,
                                payment,
                                member,
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),
                          const Divider(
                            color: AppColors.borderSubtle,
                            height: 1,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Member Account Info
                          Text(
                            'Member Information',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Name: ${member?.name ?? 'Alex Morgan'}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Member ID: ${member?.id ?? 'GM-1024'}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Membership: ${member?.membershipPlan ?? 'Premium'}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: mainDetailsCard,
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          Expanded(
                            flex: 4,
                            child: sidebarActionCard,
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        mainDetailsCard,
                        const SizedBox(height: AppSpacing.xl),
                        sidebarActionCard,
                      ],
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
