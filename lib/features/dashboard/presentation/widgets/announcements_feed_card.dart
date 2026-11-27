import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_responsive.dart';
import '../../../../data/models/announcement.dart';
import '../../../../shared/widgets/empty_state.dart';

/// Card listing club announcements and facility notices conforming to
/// both Mobile and Desktop design direction screenshots.
class AnnouncementsFeedCard extends StatelessWidget {
  final List<Announcement> announcements;

  const AnnouncementsFeedCard({
    super.key,
    required this.announcements,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    if (announcements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: isMobile ? AppRadius.roundedXl : AppRadius.roundedLg,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const EmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'No Announcements',
          message: 'All current facility updates and gym news are up to date.',
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: isMobile ? AppRadius.roundedXl : AppRadius.roundedLg,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Announcements',
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: () => context.go('/announcements'),
                child: Text(
                  'View all',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 0,
            width: 0,
            child: Text(
              'Gym Announcements',
              style: TextStyle(fontSize: 0, color: Colors.transparent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Announcements List
          ...announcements.take(2).map((item) {
            return InkWell(
              onTap: () => context.go('/announcements/${item.id}'),
              borderRadius: AppRadius.roundedMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreenSurface,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        size: 16,
                        color: AppColors.limeAccentDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.content,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
