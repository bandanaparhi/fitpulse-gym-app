import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/announcement.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/info_card.dart';

/// Card listing recent club and facility notices.
class AnnouncementsFeedCard extends StatelessWidget {
  final List<Announcement> announcements;

  const AnnouncementsFeedCard({
    super.key,
    required this.announcements,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return InfoCard(
        title: 'Gym Announcements',
        icon: Icons.campaign_outlined,
        child: const EmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'No Announcements',
          message: 'All current facility updates and gym news are up to date.',
        ),
      );
    }

    return InfoCard(
      title: 'Gym Announcements',
      subtitle: 'Facility updates & member alerts',
      icon: Icons.campaign_outlined,
      trailing: TextButton(
        onPressed: () => context.go('/announcements'),
        child: const Text('View All'),
      ),
      child: Column(
        children: announcements.take(2).map((item) {
          return InkWell(
            onTap: () => context.go('/announcements/${item.id}'),
            borderRadius: AppRadius.roundedMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: item.isUrgent
                          ? AppColors.errorBg
                          : AppColors.limeAccent.withValues(alpha: 0.15),
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Icon(
                      item.isUrgent ? Icons.priority_high_rounded : Icons.article_outlined,
                      size: 16,
                      color: item.isUrgent ? AppColors.error : AppColors.limeAccentDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              AppFormatters.formatShortDate(item.date),
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.content,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Posted by ${item.author}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textMuted),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
