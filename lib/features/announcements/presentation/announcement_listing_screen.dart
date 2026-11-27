import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_responsive.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_header.dart';
import 'widgets/announcement_card.dart';

/// Screen displaying published official gym announcements at `/announcements`.
class AnnouncementListingScreen extends ConsumerStatefulWidget {
  const AnnouncementListingScreen({super.key});

  @override
  ConsumerState<AnnouncementListingScreen> createState() =>
      _AnnouncementListingScreenState();
}

class _AnnouncementListingScreenState
    extends ConsumerState<AnnouncementListingScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    // Only published announcements are provided
    final announcements = ref.watch(announcementsProvider);

    // Extract available categories
    final categories = [
      'All',
      ...{for (final a in announcements) a.category},
    ];

    final filteredAnnouncements = announcements.where((a) {
      if (_selectedCategory == 'All') return true;
      return a.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            const PageHeader(
              title: 'Gym Announcements & Notices',
              subtitle:
                  'Official facility updates, equipment enhancements, operational schedules, and club events.',
            ),

            // Category Filter Chips
            if (announcements.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final count = cat == 'All'
                      ? announcements.length
                      : announcements
                          .where((a) =>
                              a.category.toLowerCase() == cat.toLowerCase())
                          .length;

                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.darkCharcoal
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.darkCharcoal
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat == 'All' ? 'All Notices' : cat,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.limeAccentDark
                                  : AppColors.cardSubtleBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: isSelected
                                  ? null
                                  : Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Announcements List or Empty State
            if (filteredAnnouncements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: EmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No Announcements',
                  message:
                      'There are currently no active announcements from gym administration in this category.',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAnnouncements.length,
                separatorBuilder: (_, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final announcement = filteredAnnouncements[index];
                  return AnnouncementCard(announcement: announcement);
                },
              ),
          ],
        ),
      ),
    );
  }
}
