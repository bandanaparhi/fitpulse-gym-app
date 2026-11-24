import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';

/// Section rendering official gym FAQs with category filtering and keyword search.
class FaqSection extends ConsumerStatefulWidget {
  const FaqSection({super.key});

  @override
  ConsumerState<FaqSection> createState() => _FaqSectionState();
}

class _FaqSectionState extends ConsumerState<FaqSection> {
  final _searchController = TextEditingController();

  static const List<String> _categories = [
    'All',
    'Facility & Access',
    'Classes & Bookings',
    'Workouts & Training',
    'Billing & Accounts',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queryState = ref.watch(faqQueryProvider);
    final faqsAsync = ref.watch(faqListProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 20,
                  color: AppColors.limeAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequently Asked Questions',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Common guidance regarding facility check-ins, classes, workouts, and memberships.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search questions by keyword...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(faqQueryProvider.notifier).setSearchQuery('');
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.cardSubtleBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.limeAccentDark,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (val) {
              ref.read(faqQueryProvider.notifier).setSearchQuery(val);
              setState(() {});
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = queryState.category == category;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppColors.limeAccent.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.limeAccentDark,
                    backgroundColor: AppColors.cardSubtleBg,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.limeAccentDark
                          : AppColors.borderSubtle,
                    ),
                    labelStyle: AppTextStyles.caption.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppColors.limeAccentDark
                          : AppColors.textPrimary,
                    ),
                    onSelected: (_) {
                      ref
                          .read(faqQueryProvider.notifier)
                          .setCategory(category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // FAQ Accordion List
          faqsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: LoadingIndicator(message: 'Loading FAQs...'),
              ),
            ),
            error: (err, _) => ErrorState(
              title: 'Unable to load FAQs',
              message: err.toString(),
              onRetry: () => ref.invalidate(faqListProvider),
            ),
            data: (faqs) {
              if (faqs.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching questions found',
                  message:
                      'Try adjusting your search keywords or selecting "All" categories.',
                );
              }

              return Column(
                children: faqs.map((faq) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Material(
                      color: AppColors.cardSubtleBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                        collapsedIconColor: AppColors.textSecondary,
                        iconColor: AppColors.limeAccentDark,
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        title: Text(
                          faq.question,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCharcoal
                                      .withValues(alpha: 0.06),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  faq.category,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: Text(
                              faq.answer,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
