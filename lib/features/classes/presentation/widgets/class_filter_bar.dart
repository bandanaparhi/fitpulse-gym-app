import 'package:material_ui/material_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_theme.dart';

/// Filter bar for filtering gym classes by date, category, and seat availability.
class ClassFilterBar extends StatelessWidget {
  final String selectedDateFilter;
  final String selectedCategory;
  final bool availableOnly;
  final ValueChanged<String> onDateFilterChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onAvailableOnlyChanged;

  const ClassFilterBar({
    super.key,
    required this.selectedDateFilter,
    required this.selectedCategory,
    required this.availableOnly,
    required this.onDateFilterChanged,
    required this.onCategoryChanged,
    required this.onAvailableOnlyChanged,
  });

  static const List<String> dateOptions = [
    'All Dates',
    'Today',
    'Tomorrow',
    'This Week',
  ];

  static const List<String> categoryOptions = [
    'All Categories',
    'Spin',
    'Yoga',
    'CrossFit',
    'Boxing',
    'Zumba',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          final dateDropdown = Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.cardSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDateFilter,
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                dropdownColor: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: dateOptions.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {
                  if (val != null) onDateFilterChanged(val);
                },
              ),
            ),
          );

          final categoryDropdown = Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.cardSubtleBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                icon: const Icon(Icons.category_outlined, size: 16),
                dropdownColor: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: categoryOptions.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {
                  if (val != null) onCategoryChanged(val);
                },
              ),
            ),
          );

          final availabilityToggle = InkWell(
            onTap: () => onAvailableOnlyChanged(!availableOnly),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: availableOnly
                    ? AppColors.limeAccent.withValues(alpha: 0.15)
                    : AppColors.cardSubtleBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: availableOnly
                      ? AppColors.limeAccentDark
                      : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    availableOnly
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: availableOnly
                        ? AppColors.limeAccentDark
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Available Spots Only',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight:
                          availableOnly ? FontWeight.bold : FontWeight.w500,
                      color: availableOnly
                          ? AppColors.darkCharcoal
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: dateDropdown),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: categoryDropdown),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                availabilityToggle,
              ],
            );
          } else {
            return Row(
              children: [
                dateDropdown,
                const SizedBox(width: AppSpacing.sm),
                categoryDropdown,
                const SizedBox(width: AppSpacing.sm),
                availabilityToggle,
              ],
            );
          }
        },
      ),
    );
  }
}
