import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/announcement.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/page_header.dart';

/// Screen displaying the full content, publication details, and attachments
/// of an official gym announcement at `/announcements/:announcementId`.
class AnnouncementDetailsScreen extends ConsumerWidget {
  final String announcementId;

  const AnnouncementDetailsScreen({
    super.key,
    required this.announcementId,
  });

  void _handleAttachmentAction(
    BuildContext context,
    AnnouncementAttachment attachment,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening attachment "${attachment.fileName}" (${attachment.fileSize})...',
        ),
        backgroundColor: AppColors.darkCharcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'facility maintenance':
        return AppColors.warning;
      case 'equipment upgrade':
        return AppColors.limeAccentDark;
      case 'events & competitions':
        return AppColors.info;
      default:
        return AppColors.darkCharcoal;
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'image':
      case 'png':
      case 'jpg':
        return Icons.image_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementAsync = ref.watch(singleAnnouncementProvider(announcementId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: announcementAsync.when(
        loading: () => const Center(
          child: LoadingIndicator(message: 'Loading announcement...'),
        ),
        error: (err, stack) => Center(
          child: ErrorState(
            title: 'Failed to load announcement',
            message: err.toString(),
            onRetry: () => ref.invalidate(singleAnnouncementProvider(announcementId)),
          ),
        ),
        data: (announcement) {
          if (announcement == null || !announcement.isPublished) {
            return Center(
              child: EmptyState(
                icon: Icons.campaign_outlined,
                title: 'Announcement Not Found',
                message:
                    'The requested announcement does not exist or has been archived by gym administration.',
                actionLabel: 'Return to Announcements',
                onAction: () => context.go('/announcements'),
              ),
            );
          }

          final categoryColor = _getCategoryColor(announcement.category);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Back Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go('/announcements'),
                      tooltip: 'Back to Announcements',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Expanded(
                      child: PageHeader(
                        title: 'Announcement Details',
                        subtitle: 'Official broadcast from gym administration.',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Main Article Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Priority
                      Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              announcement.category.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          if (announcement.isUrgent || announcement.isImportant)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                announcement.priority.toUpperCase(),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Title
                      Text(
                        announcement.title,
                        style: AppTextStyles.h2,
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Publication Meta Row
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Published on ${AppFormatters.formatDate(announcement.date)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'By ${announcement.author}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      const Divider(color: AppColors.borderSubtle, height: 1),
                      const SizedBox(height: AppSpacing.xl),

                      // Full Announcement Content
                      Text(
                        announcement.content,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                      ),

                      // Valid Attachments Section
                      if (announcement.attachments.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        const SizedBox(height: AppSpacing.lg),

                        Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 18,
                              color: AppColors.darkCharcoal,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Attachments & Documents (${announcement.attachments.length})',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: announcement.attachments.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final attachment = announcement.attachments[index];
                            final icon = _getFileIcon(attachment.fileType);

                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.cardSubtleBg,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border:
                                    Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 20,
                                      color: AppColors.darkCharcoal,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          attachment.fileName,
                                          style: AppTextStyles.bodySmall.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${attachment.fileType.toUpperCase()} • ${attachment.fileSize}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: 8,
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.borderSubtle,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.md,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.download_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Download'),
                                    onPressed: () => _handleAttachmentAction(
                                      context,
                                      attachment,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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
